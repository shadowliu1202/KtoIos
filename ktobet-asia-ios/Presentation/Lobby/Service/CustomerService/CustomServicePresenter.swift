import RxCocoa
import RxRelay
import RxSwift
import RxSwiftExt
import SharedBu
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
  static let shared: CustomServicePresenter = Injectable.resolve(CustomServicePresenter.self)!

  private let storyboard = UIStoryboard(name: "CustomService", bundle: nil)
  private let isCSIconAppear = BehaviorRelay(value: false)
  private let disposeBag = DisposeBag()

  private(set) var ballWindow: CustomerServiceIconViewWindow?
  private(set) var csViewModel: CustomerServiceViewModel {
    didSet {
      initService()
    }
  }

  private var surveyViewModel: SurveyViewModel

  lazy var observeCsStatus: Observable<Bool> = isCSIconAppear.skip(1).share(replay: 1)

  var isInSideMenu = false {
    willSet(inSideMenu) {
      guard isCSIconAppear.value else { return }
      if inSideMenu {
        self.ballWindow?.isHidden = true
      }
      else {
        self.ballWindow?.isHidden = false
      }
    }
  }

  var isInGameWebView = false {
    willSet(inGameWebView) {
      guard isCSIconAppear.value else { return }
      if inGameWebView {
        self.ballWindow?.isHidden = true
      }
      else {
        self.ballWindow?.isHidden = false
      }
    }
  }

  var isInCallingView = false {
    willSet(inCallingView) {
      if inCallingView {
        self.ballWindow?.isHidden = true
      }
    }
  }

  var isInChatRoom: Bool {
    topViewController is ChatRoomViewController
  }

  var isInChat: Bool {
    if
      isInChatRoom ||
      isInCallingView ||
      isCSIconAppear.value
    {
      return true
    }
    return false
  }

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
    Logger.shared.info("\(type(of: self)) init.")
    csViewModel = customerServiceViewModel
    self.surveyViewModel = surveyViewModel
    super.init()
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

  func initService() {
    Logger.shared.info("CustomerService init.")

    ballWindow = nil
    addServiceIcon()
    
    csViewModel
      .preLoadChatRoomStatus
      .first()
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [weak self] status in
        guard
          let self,
          let status
        else { return }

        switch status {
        case .notexist:
          self.hiddenServiceIcon()
        case .connected:
          if !self.isInChatRoom {
            self.collapse()
          }
        case .connecting:
          self.setServiceIconTap {
            self.switchToCalling(isRoot: true, svViewModel: self.surveyViewModel)
            self.hiddenServiceIcon()
          }

          if !self.isInCallingView {
            self.showServiceIcon()
          }
        case .closed:
          self.setServiceIconTap {
            self.switchToChatRoom(isRoot: true)
            self.hiddenServiceIcon()
          }

          if !self.isInChatRoom {
            self.showServiceIcon()
          }
        default:
          break
        }
      })
      .disposed(by: disposeBag)
  }

  private func setServiceIconTap(touchEvent: (() -> Void)?) {
    if let event = touchEvent {
      ballWindow?.touchUpInside = event
    }
  }

  func showServiceIcon() {
    self.ballWindow?.isHidden = false
    isCSIconAppear.accept(true)
  }

  func hiddenServiceIcon() {
    self.ballWindow?.isHidden = true
    isCSIconAppear.accept(false)
  }

  func startCustomerService(from vc: UIViewController) -> Completable {
    let csViewModel = self.csViewModel
    let surveyViewModel = self.surveyViewModel
    return surveyViewModel.getPreChatSurvey()
      .do(onSuccess: { [unowned self] (info: Survey) in
        if info.surveyQuestions.isEmpty {
          self.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
        }
        else {
          self.switchToPrechat(from: vc, vm: surveyViewModel, csViewModel: csViewModel)
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

  private func switchToPrechat(from vc: UIViewController?, vm: SurveyViewModel, csViewModel: CustomerServiceViewModel) {
    let prechatVC = storyboard
      .instantiateViewController(identifier: "PrechatServeyViewController") as PrechatServeyViewController
    prechatVC.bind(position: .left, barButtonItems: .kto(.close))
    let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
    prechatVC.bind(position: .right, barButtonItems: padding, skip)
    prechatVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    prechatVC.viewModel = vm
    prechatVC.csViewModel = csViewModel
    let navi = storyboard
      .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
    navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    navi.setViewControllers([prechatVC], animated: false)
    vc?.present(navi, animated: true, completion: nil)
  }

  func switchToCalling(isRoot: Bool = false, svViewModel: SurveyViewModel? = nil) {
    let callingVC = storyboard.instantiateViewController(identifier: "CallingViewController") as CallingViewController
    callingVC.bind(position: .left, barButtonItems: .kto(.close))
    callingVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    callingVC.csViewModel = csViewModel
    callingVC.svViewModel = svViewModel
    if isRoot {
      let navi = storyboard
        .instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
      navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
      navi.setViewControllers([callingVC], animated: false)
      topViewController?.present(navi, animated: false, completion: nil)
    }
    else {
      guard topViewController?.navigationController is CustomServiceNavigationController
      else {
        let navigationControllerName = topViewController?.navigationController?.description ?? ""
        fatalError("Wrong NavigationController: \(navigationControllerName)")
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
      navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
      navi.setViewControllers([chatRoomVC], animated: false)
      topViewController?.present(navi, animated: true, completion: nil)
    }
    else {
      Alert.shared.dismiss { [weak self] in
        self?.setToChatRoom(chatRoomVC)
      }
    }
  }
  
  private func setToChatRoom(_ chatRoomVC: ChatRoomViewController) {
    guard topViewController?.navigationController is CustomServiceNavigationController
    else {
      let navigationControllerName = topViewController?.navigationController?.description ?? ""
      fatalError("Wrong NavigationController: \(navigationControllerName)")
    }
    
    topViewController?.navigationController?.setViewControllers([chatRoomVC], animated: false)
  }

  func switchToOfflineMessage(from vc: UIViewController?, isRoot: Bool = false) {
    let offlineMessageVC = storyboard
      .instantiateViewController(identifier: "OfflineMessageViewController") as OfflineMessageViewController
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
        fatalError("check NavigationController of presented VC")
      }
      vc?.navigationController?.setViewControllers([offlineMessageVC], animated: false)
    }
  }

  func switchToExitSurvey(roomId: RoomId) {
    let exitSurveyVC = storyboard
      .instantiateViewController(identifier: "ExitSurveyViewController") as ExitSurveyViewController
    exitSurveyVC.bind(position: .left, barButtonItems: .kto(.close))
    let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
    exitSurveyVC.bind(position: .right, barButtonItems: padding, skip)
    exitSurveyVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    exitSurveyVC.viewModel = surveyViewModel
    exitSurveyVC.roomId = roomId
    self.topViewController?.navigationController?.setViewControllers([exitSurveyVC], animated: false)
  }

  func closeService() -> Completable {
    closeChatRoomIfExist()
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
    hiddenServiceIcon()
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

  func collapse() {
    self.setServiceIconTap {
      self.switchToChatRoom(isRoot: true)
      self.hiddenServiceIcon()
    }

    showServiceIcon()
    csViewModel.minimize().subscribe(onCompleted: { }).disposed(by: disposeBag)
    topViewController?.navigationController?.dismiss(animated: true, completion: { [weak self] in
      NavigationManagement.sharedInstance.viewController = self?.topViewController
    })
  }

  func changeCsDomainIfNeed() {
    csViewModel.preLoadChatRoomStatus
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
