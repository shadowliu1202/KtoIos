import UIKit
import RxSwift
import RxCocoa
import SharedBu
import RxRelay
import RxSwiftExt

let endChatBarBtnId = 1003
let collapseBarBtnId = 1004

protocol CustomServiceDelegate: AnyObject {
    func customServiceBarButtons() -> [UIBarButtonItem]?
    func didCsIconAppear(isAppear: Bool)
}

extension CustomServiceDelegate where Self: BarButtonItemable, Self: UIViewController  {
    func didCsIconAppear(isAppear: Bool) {
        if isAppear {
            removeCustomServiceBarButtons()
        } else {
            reAddCustomServiceBarButtons()
        }
    }
    
    private func reAddCustomServiceBarButtons() {
        self.bind(position: .right, barButtonItems: barButtonItems)
    }
    
    private func removeCustomServiceBarButtons() {
        if let csItems = customServiceBarButtons() {
            let items = barButtonItems.filter({ !csItems.contains($0)})
            self.bind(position: .right, barButtonItems: items)
        }
    }
}


class CustomServicePresenter: NSObject {
    static var shared: CustomServicePresenter = DI.resolve(CustomServicePresenter.self)!
    
    var isInSideMenu: Bool = false {
        willSet(inSideMenu) {
            guard isCSIconAppear.value else { return }
            if inSideMenu {
                self.ballWindow?.isHidden = true
            } else {
                self.ballWindow?.isHidden = false
            }
        }
    }
    
    var isInGameWebView: Bool = false {
        willSet(inGameWebView) {
            guard isCSIconAppear.value else { return }
            if inGameWebView {
                self.ballWindow?.isHidden = true
            } else {
                self.ballWindow?.isHidden = false
            }
        }
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
    
    var csViewModel: CustomerServiceViewModel
    var surveyViewModel: SurveyViewModel
    lazy var observeCsIcon: Observable<Bool> = isCSIconAppear.share(replay: 1)
    var chatRoomConnectStatus: Observable<PortalChatRoom.ConnectStatus> { csViewModel.preLoadChatRoomStatus.share(replay: 1) }
    
    private(set) var ballWindow: CustomerServiceIconViewWindow?
    
    private let storyboard = UIStoryboard(name: "CustomService", bundle: nil)
    private let isCSIconAppear = BehaviorRelay.init(value: false)
    private let disposeBag = DisposeBag()
    private var testDisposeBag = DisposeBag()
    
    init(_ customerServiceViewModel: CustomerServiceViewModel, _ surveyViewModel: SurveyViewModel) {
        csViewModel = customerServiceViewModel
        self.surveyViewModel = surveyViewModel
        super.init()
        addServiceIcon()
    }
    
    private func addServiceIcon() {
        if ballWindow == nil {
            var rightPadding: CGFloat = 80
            var bottomPadding: CGFloat = 80
            if let window = UIApplication.shared.windows.first {
                rightPadding += window.safeAreaInsets.right
                bottomPadding += window.safeAreaInsets.bottom
            }
            
            ballWindow = CustomerServiceIconViewWindow(frame: CGRect(x: UIScreen.main.bounds.width - rightPadding, y: UIScreen.main.bounds.height - bottomPadding, width: 56, height: 56), viewModel: csViewModel)
        }
    }
    
    func initCustomerService() -> Completable {
        self.csViewModel.searchChatRoom().asCompletable().andThen(self.csViewModel.preLoadChatRoomStatus)
            .first()
            .observeOn(MainScheduler.asyncInstance)
            .do(onSuccess: { status in
                guard let status = status else { return }
                switch status {
                case .notexist:
                    self.hiddenServiceIcon()
                case .connected:
                    self.setServiceIconTap {
                        self.switchToChatRoom(isRoot: true)
                        self.hiddenServiceIcon()
                    }
                    
                    self.showServiceIcon()
                case .connecting:
                    self.setServiceIconTap {
                        self.switchToCalling(isRoot: true, svViewModel: self.surveyViewModel)
                        self.hiddenServiceIcon()
                    }
                    
                    self.showServiceIcon()
                case .closed:
                    self.setServiceIconTap {
                        self.switchToChatRoom(isRoot: true)
                        self.hiddenServiceIcon()
                    }
                    
                    self.showServiceIcon()
                default:
                    break
                }
            }).asCompletable()
    }
    
    private func setServiceIconTap(touchEvent: (() -> ())?) {
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
        return csViewModel.checkServiceAvailable().flatMap({ (isAvailable) in
            if isAvailable {
                return surveyViewModel.getPreChatSurvey()
            } else {
                return Single.error(ServiceUnavailableException())
            }
        }).do(onSuccess: { [unowned self] (info: Survey) in
            if info.surveyQuestions.isEmpty {
                self.switchToCalling(isRoot: true, svViewModel: surveyViewModel)
            } else {
                self.switchToPrechat(from: vc, vm: surveyViewModel, csViewModel: csViewModel)
            }
        }).asCompletable()
            .catchError({ (error) in
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
        let prechatVC = storyboard.instantiateViewController(identifier: "PrechatServeyViewController") as PrechatServeyViewController
        prechatVC.bind(position: .left, barButtonItems: .kto(.close))
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
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
        chatRoomVC.surveyViewModel = surveyViewModel
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
            if let currentVC = topViewController as? UIAdaptivePresentationControllerDelegate {
                chatRoomVC.presentationController?.delegate = currentVC
            }
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
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
        exitSurveyVC.bind(position: .right, barButtonItems: padding, skip)
        exitSurveyVC.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
        exitSurveyVC.viewModel = surveyViewModel
        exitSurveyVC.roomId = roomId
        exitSurveyVC.skillId = skillId
        self.topViewController?.navigationController?.setViewControllers([exitSurveyVC], animated: false)
    }
    
    func close(completion: (() -> Void)? = nil) {
        csViewModel.closeChatRoom()
            .subscribe(onCompleted: {[weak self] in
                self?.cleanSurveyAnswers()
                self?.hiddenServiceIcon()
                print("close room")
            }).disposed(by: disposeBag)
        
        topViewController?.navigationController?.dismiss(animated: true, completion: {[weak self] in
            NavigationManagement.sharedInstance.viewController = self?.topViewController
            completion?()
        })
        
        changeCsDomainIfNeed()
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
        csViewModel.minimize().subscribe(onCompleted: {}).disposed(by: disposeBag)
        topViewController?.navigationController?.dismiss(animated: true, completion: {[weak self] in
            NavigationManagement.sharedInstance.viewController = self?.topViewController
        })
    }
    
    func observeCsStatus(by delegate: CustomServiceDelegate, _ disposeBag: DisposeBag) {
        observeCsIcon
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: delegate.didCsIconAppear).disposed(by: disposeBag)
    }
    
    func changeCsDomainIfNeed() {
        chatRoomConnectStatus.first()
            .map({ connectStatus in
                connectStatus == PortalChatRoom.ConnectStatus.notexist
            })
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [unowned self] noConnectStatus in
                if noConnectStatus {
                    self.csViewModel = DI.resolve(CustomerServiceViewModel.self)!
                    self.surveyViewModel = DI.resolve(SurveyViewModel.self)!
                }
            }).disposed(by: disposeBag)
    }
}
