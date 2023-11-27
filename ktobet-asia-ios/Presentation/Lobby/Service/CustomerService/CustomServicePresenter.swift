import RxCocoa
import RxRelay
import RxSwift
import RxSwiftExt
import sharedbu
import UIKit

let endChatBarBtnId = 1003
let collapseBarBtnId = 1004

typealias RoomId = String
typealias SkillId = String
typealias TotalCount = Int

protocol CustomServiceDelegate: AnyObject {
  func customServiceBarButtons() -> [UIBarButtonItem]?
  func didCsIconAppear(isAppear: Bool)
}

extension CustomServiceDelegate where Self: BarButtonItemable, Self: UIViewController {
  func didCsIconAppear(isAppear: Bool) {
    if isAppear {
      removeCustomServiceBarButtons()
    }
    else {
      reAddCustomServiceBarButtons()
    }
  }

  private func reAddCustomServiceBarButtons() {
    self.bind(position: .right, barButtonItems: barButtonItems)
  }

  private func removeCustomServiceBarButtons() {
    if let csItems = customServiceBarButtons() {
      let items = barButtonItems.filter({ !csItems.contains($0) })
      self.bind(position: .right, barButtonItems: items)
    }
  }
}

class CustomServicePresenter: NSObject {
  enum ChatWindowState {
    case fullscreen
    case minimize
  }
  
  static let shared: CustomServicePresenter = Injectable.resolve(CustomServicePresenter.self)!

  private let storyboard = UIStoryboard(name: "CustomService", bundle: nil)
  private let floatIconAvailableRelay = BehaviorRelay(value: true)
  private let chatWindowStateRelay = BehaviorRelay(value: ChatWindowState.minimize)
  
  private var disposeBag = DisposeBag()

  private(set) var ballWindow: CustomerServiceIconViewWindow?
  private(set) var csViewModel: CustomerServiceViewModel {
    didSet {
      initService()
    }
  }

  private var surveyViewModel: SurveyViewModel
  
  var topViewController: UIViewController? {
    if let root = UIApplication.shared.windows.first?.topViewController as? UINavigationController {
      if let top = root.topViewController {
        return top
      }

      return root
    }

    return nil
  }

  init(_ customerServiceViewModel: CustomerServiceViewModel, _ surveyViewModel: SurveyViewModel) {
    csViewModel = customerServiceViewModel
    self.surveyViewModel = surveyViewModel
    super.init()
  }

  func initService() {
    Logger.shared.info("CustomerService init.")

    ballWindow = nil
    disposeBag = .init()
    addServiceIcon()
    
    bindFloatIconDisplayStatus()
    bindChatWindowState()
    bindFloatIconOnTap()
  }
  
  private func addServiceIcon() {
    if ballWindow == nil {
      var rightPadding: CGFloat = 80
      var bottomPadding: CGFloat = 80
      if let window = UIApplication.shared.windows.first {
        rightPadding += window.safeAreaInsets.right
        bottomPadding += window.safeAreaInsets.bottom
      }

      ballWindow = CustomerServiceIconViewWindow(
        frame: CGRect(
          x: UIScreen.main.bounds.width - rightPadding,
          y: UIScreen.main.bounds.height - bottomPadding,
          width: 56,
          height: 56),
        viewModel: csViewModel)
    }
  }

  private func bindFloatIconDisplayStatus() {
    Driver.combineLatest(
      csViewModel.isPlayerInChat.asDriverOnErrorJustComplete(),
      floatIconAvailableRelay.asDriver()) { ($0, $1) }
      .drive(onNext: { [ballWindow] in
        let (isPlayerInChat, floatIconAvailable) = $0
        let available = floatIconAvailable && isPlayerInChat
        
        ballWindow?.isHidden = !available
      })
      .disposed(by: disposeBag)
  }
  
  private func bindChatWindowState() {
    Observable.combineLatest(
      chatWindowStateRelay.asObservable(),
      csViewModel.chatRoomStatus.filter { $0 == PortalChatRoom.ConnectStatus.connected })
      .subscribe(onNext: { [csViewModel] state, _ in
        Task {
          switch state {
          case .fullscreen:
            try? await csViewModel.markAllRead(manual: nil, auto: true)
          case .minimize:
            try? await csViewModel.markAllRead(manual: nil, auto: false)
          }
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func bindFloatIconOnTap() {
    guard let ballWindow else { return }
    
    ballWindow.touchUpInside
      .asObservable()
      .flatMap { [csViewModel] in csViewModel.chatRoomStatus.first() }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] status in
        guard let status else { return }
          
        switch status {
        case .notexist: break
        case .connected: switchToChatRoom(isRoot: true)
        case .connecting: switchToCalling(isRoot: true, svViewModel: surveyViewModel)
        case .closed: switchToChatRoom(isRoot: true)
        default: break
        }
      })
      .disposed(by: disposeBag)
  }
  
  func setFloatIconAvailable(_ available: Bool) {
    floatIconAvailableRelay.accept(available)
  }
  
  func setChatWindowState(_ state: ChatWindowState) {
    chatWindowStateRelay.accept(state)
  }

  func startCustomerService(from vc: UIViewController) -> Completable {
    let csViewModel = self.csViewModel
    let surveyViewModel = self.surveyViewModel
    return surveyViewModel.getPreChatSurvey()
      .observe(on: MainScheduler.instance)
      .do(onSuccess: { [unowned self] (info: Survey) in
        if info.surveyQuestions.isEmpty {
          self.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
        }
        else {
          self.switchToPrechat(from: vc)
        }
      })
      .asCompletable()
      .catch({ error in
        switch error {
        case is ServiceUnavailableException:
          self.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
          return Completable.empty()
        default:
          return Completable.error(error)
        }
      })
  }

  func switchToPrechat(from vc: UIViewController?) {
    let prechatVC = PrechatSurveyViewController()
    let navi = storyboard
      .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
    navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    navi.setViewControllers([prechatVC], animated: false)
    vc?.present(navi, animated: true, completion: nil)
  }

  func switchToCalling(isRoot: Bool = false, svViewModel _: SurveyViewModel? = nil) {
    let callingVC = CallingViewController(surveyAnswers: nil)
    if isRoot {
      let navi = storyboard
        .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
      navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
      navi.setViewControllers([callingVC], animated: false)
      topViewController?.present(navi, animated: false, completion: nil)
    }
    else {
      guard topViewController?.navigationController is CustomServiceNavigationController
      else {
        guard
          let targetViewController = findNavigationController() as? CustomServiceNavigationController else { return }
        targetViewController.setViewControllers([callingVC], animated: false)
        topViewController?.present(targetViewController, animated: true, completion: nil)
        return
      }
      topViewController?.navigationController?.setViewControllers([callingVC], animated: false)
    }
  }

  func switchToChatRoom(isRoot: Bool = false) {
    let chatRoomVC = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as ChatRoomViewController
    chatRoomVC.viewModel = csViewModel
    chatRoomVC.surveyViewModel = surveyViewModel
    let chatTitle = UIBarButtonItem.kto(.text(text: Localize.string("customerservice_chat_room_title"))).isEnable(false)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont(name: "PingFangSC-Semibold", size: 16.0)!,
      .foregroundColor: UIColor.greyScaleWhite
    ]
    chatTitle.setTitleTextAttributes(attributes, for: .disabled)
    chatTitle.setTitleTextAttributes(attributes, for: .normal)
    chatRoomVC.bind(position: .left, barButtonItems: chatTitle)
    let endChat = UIBarButtonItem.kto(.customIamge(named: "End Chat")).senderId(endChatBarBtnId)
    let collapse = UIBarButtonItem.kto(.customIamge(named: "Collapse")).senderId(collapseBarBtnId)
    chatRoomVC.bind(position: .right, barButtonItems: endChat, collapse)
    chatRoomVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    if isRoot {
      let navi = storyboard
        .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
      navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
      navi.setViewControllers([chatRoomVC], animated: false)
      topViewController?.present(navi, animated: true, completion: nil)
    }
    else {
      setToChatRoom(chatRoomVC)
    }
  }
  
  func setToChatRoom(_ chatRoomVC: ChatRoomViewController) {
    guard topViewController?.navigationController is CustomServiceNavigationController
    else {
      guard
        let targetViewController = findNavigationController() as? CustomServiceNavigationController else { return }
      targetViewController.setViewControllers([chatRoomVC], animated: false)
      topViewController?.present(targetViewController, animated: true, completion: nil)
      return
    }
    
    topViewController?.navigationController?.setViewControllers([chatRoomVC], animated: false)
  }
  
  private func findNavigationController() -> UIViewController? {
    let rootViewController = UIApplication.shared.windows.first?.rootViewController
    let presentedViewController = rootViewController?.presentedViewController
    let controllersToCheck = [rootViewController, presentedViewController] + (rootViewController?.children ?? [])
    for controller in controllersToCheck {
      if let customController = controller as? CustomServiceNavigationController {
        return customController
      }
    }
    return nil
  }

  func switchToOfflineMessage(from vc: UIViewController?, isRoot: Bool = false) {
    let offlineMessageVC = OfflineMessageViewController()
    let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
    offlineMessageVC.bind(position: .right, barButtonItems: padding, skip)
    offlineMessageVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    if isRoot {
      let navi = storyboard
        .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
      navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
      navi.setViewControllers([offlineMessageVC], animated: false)
      vc?.present(navi, animated: true, completion: nil)
    }
    else {
      guard vc?.navigationController is CustomServiceNavigationController else {
        guard
          let targetViewController = findNavigationController() as? CustomServiceNavigationController else { return }
        targetViewController.setViewControllers([offlineMessageVC], animated: false)
        topViewController?.present(targetViewController, animated: true, completion: nil)
        return
      }
      vc?.navigationController?.setViewControllers([offlineMessageVC], animated: false)
    }
  }

  func switchToExitSurvey(roomId: RoomId) {
    let exitSurveyVC = ExitSurveyViewController(roomID: roomId)
    self.topViewController?.navigationController?.setViewControllers([exitSurveyVC], animated: false)
  }

  func closeService() -> Completable {
    closeChatRoomIfExist()
      .observe(on: MainScheduler.instance)
      .do(onCompleted: { [weak self] in
        Injectable.resetObjectScope(.locale)
        self?.resetStatus()
      })
  }
  
  private func closeChatRoomIfExist() -> Completable {
    csViewModel.currentChatRoom()
      .take(1)
      .flatMap { [csViewModel] chatRoom -> Completable in
        if chatRoom.roomId.isEmpty {
          return Single.just(()).asCompletable()
        }
        else {
          return csViewModel.closeChatRoom(forceExit: true).asCompletable()
        }
      }
      .asCompletable()
  }
  
  func resetStatus() {
    cleanSurveyAnswers()
    Logger.shared.info("Customer service status reset.")

    changeCsDomainIfNeed()
    
    topViewController?.navigationController?
      .dismiss(animated: true, completion: { [weak self] in
        NavigationManagement.sharedInstance.viewController = self?.topViewController
      })
  }

  private func cleanSurveyAnswers() {
    csViewModel.setupSurveyAnswer(answers: nil)
  }

  func changeCsDomainIfNeed() {
    csViewModel.chatRoomStatus
      .first()
      .map({ connectStatus in
        connectStatus == PortalChatRoom.ConnectStatus.notexist
      })
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [unowned self] noConnectStatus in
        if noConnectStatus {
          self.csViewModel = Injectable.resolve(CustomerServiceViewModel.self)!
          self.surveyViewModel = Injectable.resolve(SurveyViewModel.self)!
        }
      }).disposed(by: disposeBag)
  }
}
