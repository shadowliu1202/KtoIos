import UIKit
import RxSwift
import RxCocoa
import SharedBu
import RxRelay
import RxSwiftExt

let CustomService = CustomServicePresenter.shared
let endChatBarBtnId = 1003
let collapseBarBtnId = 1004

protocol CustomServiceDelegate: AnyObject {
    func customServiceBarButtons() -> [UIBarButtonItem]?
    func monitorChatRoomStatus(_ disposeBag: DisposeBag)
    func sessionClosed()
    func removeCustomServiceBarButtons()
}

extension CustomServiceDelegate where Self: BarButtonItemable, Self: UIViewController  {
    func sessionClosed() {
        reAddCustomServiceBarButtons()
    }
    
    private func reAddCustomServiceBarButtons() {
        self.bind(position: .right, barButtonItems: barButtonItems)
    }
    
    func removeCustomServiceBarButtons() {
        if let csItems = customServiceBarButtons() {
            let items = barButtonItems.filter({ !csItems.contains($0)})
            self.bind(position: .right, barButtonItems: items)
        }
    }
    
    func monitorChatRoomStatus(_ disposeBag: DisposeBag) {
        CustomService.iconOb
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] isHidden in
                guard let self = self else { return }
                if isHidden {
                    self.sessionClosed()
                } else {
                    self.removeCustomServiceBarButtons()
                }
            }).disposed(by: disposeBag)
    }
}

class CustomServicePresenter: NSObject {
    static let shared = CustomServicePresenter()
    weak var delegate: CustomServiceDelegate?
    let storyboard = UIStoryboard(name: "CustomService", bundle: nil)
    
    fileprivate var csViewModel = DI.resolve(CustomerServiceViewModel.self)!
    fileprivate var surveyViewModel = DI.resolve(SurveyViewModel.self)!

    private(set)var ballWindow: CustomerServiceIconViewWindow?
    
    private let disposeBag = DisposeBag()
    
    var topViewController: UIViewController? {
        if let root = UIApplication.shared.windows.first?.topViewController as? UINavigationController {
            if let top = root.topViewController {
                return top
            }
            
            return root
        }
        
        return nil
    }
    
    lazy var chatRoomConnectStatus = iconOb
    
    func observeCustomerService() -> Completable {
        Completable.create {[weak self] completable in
            guard let self = self else {  return Disposables.create() }
            self.addServiceIcon()
            self.csViewModel.searchChatRoom().subscribe(onError: { error in completable(.error(error)) }).disposed(by: self.disposeBag)
            Observable.combineLatest(self.csViewModel.screenSizeOption, self.csViewModel.preLoadChatRoomStatus)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: {(size, status) in
                    if size == .Minimize {
                        switch status {
                        case .notexist:
                            self.hiddenServiceIcon()
                        case .connected:
                            self.setServiceIconTap() { self.switchToChatRoom(isRoot: true) }
                            self.showServiceIcon()
                        case .connecting:
                            self.setServiceIconTap() { self.switchToCalling(isRoot: true, svViewModel: self.surveyViewModel) }
                            self.showServiceIcon()
                        case .closed:
                            self.setServiceIconTap() { self.switchToChatRoom(isRoot: true) }
                            self.showServiceIcon()
                        default:
                            break
                        }
                        completable(.completed)
                    } else {
                        self.hiddenServiceIcon()
                    }
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
    
    fileprivate var isHiddenIcon = BehaviorRelay<Bool>(value: true)
    fileprivate lazy var iconOb: Observable<Bool> = Observable.combineLatest(csViewModel.preLoadChatRoomStatus, isHiddenIcon)
        .map{ $0 == PortalChatRoom.ConnectStatus.notexist || $1 }
        .share(replay: 1)

    private func addServiceIcon() {
        if ballWindow == nil {
            var rightPadding: CGFloat = 80
            var bottomPadding: CGFloat = 80
            if let window = UIApplication.shared.windows.first {
                rightPadding += window.safeAreaInsets.right
                bottomPadding += window.safeAreaInsets.bottom
            }
            
            ballWindow = CustomerServiceIconViewWindow(frame: CGRect(x: UIScreen.main.bounds.width - rightPadding, y: UIScreen.main.bounds.height - bottomPadding, width: 56, height: 56), viewModel: csViewModel)
            iconOb.bind(to: self.ballWindow!.rx.isHidden).disposed(by: disposeBag)

        }
    }
    
    private func setServiceIconTap(touchEvent: (() -> ())?) {
        if let event = touchEvent {
            ballWindow?.touchUpInside = event
        }
    }
    
    func removeServiceIcon() {
        ballWindow = nil
    }
    
    var isInSideMenu: Bool = false
    func showServiceIcon() {
        if isInSideMenu { return }
        self.isHiddenIcon.accept(false)
    }
    
    func hiddenServiceIcon() {
        self.isHiddenIcon.accept(true)
    }
    
    func startCustomerService(from vc: UIViewController, delegate: CustomServiceDelegate?) -> Completable {
        self.delegate = delegate
        delegate?.removeCustomServiceBarButtons()
        let csViewModel = self.csViewModel
        let surveyViewModel = self.surveyViewModel
        return csViewModel.checkServiceAvailable().flatMap({ (isAvailable) in
            if isAvailable {
                return surveyViewModel.getPreChatSurvey()
            } else {
                return Single.error(ServiceUnavailableException())
            }
        }).do(onSuccess: { (info: Survey) in
            if info.surveyQuestions.isEmpty {
                CustomService.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
            } else {
                CustomService.switchToPrechat(from: vc, vm: surveyViewModel, csViewModel: csViewModel)
            }
        }).asCompletable()
            .catchError({ (error) in
                switch error {
                case is ServiceUnavailableException:
                    CustomService.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
                    return Completable.empty()
                default:
                    delegate?.sessionClosed()
                    return Completable.error(error)
                }
            })
    }
    
    private func switchToPrechat(from vc: UIViewController?, vm: SurveyViewModel, csViewModel: CustomerServiceViewModel) {
        let prechatVC = storyboard.instantiateViewController(identifier: "PrechatServeyViewController") as PrechatServeyViewController
        prechatVC.bind(position: .left, barButtonItems: .kto(.close))
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
        prechatVC.bind(position: .right, barButtonItems: padding, skip)
        prechatVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
        prechatVC.viewModel = vm
        prechatVC.csViewModel = csViewModel
        let navi = storyboard.instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
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
            let navi = storyboard.instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
            navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            navi.setViewControllers([callingVC], animated: false)
            topViewController?.present(navi, animated: false, completion: nil)
        } else {
            guard topViewController?.navigationController is CustomServiceNavigationController else {
                fatalError("check NavigationController of presented VC")
            }
            topViewController?.navigationController?.setViewControllers([callingVC], animated: false)
        }
    }
    
    func switchToChatRoom(isRoot: Bool = false) {
        let chatRoomVC = storyboard.instantiateViewController(identifier: "ChatRoomViewController") as ChatRoomViewController
        chatRoomVC.viewModel = csViewModel
        let chatTitle = UIBarButtonItem.kto(.text(text: Localize.string("customerservice_chat_room_title"))).isEnable(false)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Semibold", size: 16.0)!,
            .foregroundColor: UIColor.whiteFull
        ]
        chatTitle.setTitleTextAttributes(attributes, for: .disabled)
        chatTitle.setTitleTextAttributes(attributes, for: .normal)
        chatRoomVC.bind(position: .left, barButtonItems: chatTitle)
        let endChat = UIBarButtonItem.kto(.customIamge(named: "End Chat")).senderId(endChatBarBtnId)
        let collapse = UIBarButtonItem.kto(.customIamge(named: "Collapse")).senderId(collapseBarBtnId)
        chatRoomVC.bind(position: .right, barButtonItems: endChat, collapse)
        chatRoomVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
        if isRoot {
            let navi = storyboard.instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
            navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            navi.setViewControllers([chatRoomVC], animated: false)
            topViewController?.present(navi, animated: true, completion: nil)
        } else {
            guard topViewController?.navigationController is CustomServiceNavigationController else {
                fatalError("check NavigationController of presented VC")
            }
            topViewController?.navigationController?.setViewControllers([chatRoomVC], animated: false)
        }
    }
    
    func switchToOfflineMessage(from vc: UIViewController?, isRoot: Bool = false) {
        let offlineMessageVC = storyboard.instantiateViewController(identifier: "OfflineMessageViewController") as OfflineMessageViewController
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
        offlineMessageVC.bind(position: .right, barButtonItems: padding, skip)
        offlineMessageVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
        offlineMessageVC.viewModel = surveyViewModel
        if isRoot {
            let navi = storyboard.instantiateViewController(withIdentifier: "CustomServiceNavigationController") as! UINavigationController
            navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            navi.setViewControllers([offlineMessageVC], animated: false)
            vc?.present(navi, animated: true, completion: nil)
        } else {
            guard vc?.navigationController is CustomServiceNavigationController else {
                fatalError("check NavigationController of presented VC")
            }
            vc?.navigationController?.setViewControllers([offlineMessageVC], animated: false)
        }
    }
    
    func switchToExitSurvey(roomId: RoomId, skillId: SkillId) {
        let exitSurveyVC = storyboard.instantiateViewController(identifier: "ExitSurveyViewController") as ExitSurveyViewController
        exitSurveyVC.bind(position: .left, barButtonItems: .kto(.close))
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
        exitSurveyVC.bind(position: .right, barButtonItems: padding, skip)
        exitSurveyVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
        exitSurveyVC.viewModel = surveyViewModel
        exitSurveyVC.roomId = roomId
        exitSurveyVC.skillId = skillId
        self.topViewController?.navigationController?.setViewControllers([exitSurveyVC], animated: false)
    }
    
    private func cleanSurveyAnswers() {
        csViewModel.setupSurveyAnswer(answers: nil)
    }
    
    func closeChatRoom() {
        csViewModel.closeChatRoom()
            .subscribe(onCompleted: {[weak self] in
                self?.cleanSurveyAnswers()
                print("close room")
            }).disposed(by: disposeBag)
    }
    
    func close(completion: (() -> Void)? = nil) {
        delegate?.sessionClosed()
        closeChatRoom()
        topViewController?.navigationController?.dismiss(animated: true, completion: {[weak self] in
            NavigationManagement.sharedInstance.viewController = self?.topViewController
            completion?()
        })
    }
    
    func collapse() {
        csViewModel.minimize().subscribe(onCompleted: {}).disposed(by: disposeBag)
        CustomServicePresenter.shared.csViewModel.minimize().subscribe(onCompleted: { }).disposed(by: disposeBag)
        topViewController?.navigationController?.dismiss(animated: true, completion: {[weak self] in
            NavigationManagement.sharedInstance.viewController = self?.topViewController
        })
    }
}
