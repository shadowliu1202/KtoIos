import RxCocoa
import RxRelay
import RxSwift
import RxSwiftExt
import sharedbu
import UIKit

protocol CustomServiceDelegate: AnyObject {
    func customServiceBarButtons() -> [UIBarButtonItem]?
    func didCsIconAppear(isAppear: Bool)
}

extension CustomServiceDelegate where Self: BarButtonItemable, Self: UIViewController {
    func didCsIconAppear(isAppear: Bool) {
        if isAppear {
            removeCustomServiceBarButtons()
        } else {
            reAddCustomServiceBarButtons()
        }
    }

    private func reAddCustomServiceBarButtons() {
        bind(position: .right, barButtonItems: barButtonItems)
    }

    private func removeCustomServiceBarButtons() {
        if let csItems = customServiceBarButtons() {
            let items = barButtonItems.filter { !csItems.contains($0) }
            bind(position: .right, barButtonItems: items)
        }
    }
}

class CustomServicePresenter: NSObject {
    static var shared: CustomServicePresenter {
        Injectable.resolve(CustomServicePresenter.self)!
    }

    private let csViewModel: CustomerServiceViewModel
    private let floatIconAvailableRelay = BehaviorRelay(value: true)

    private var disposeBag = DisposeBag()

    private var ballWindow: CustomerServiceIconViewWindow?

    var topViewController: UIViewController? {
        guard let topViewController = UIApplication.shared.windows.first?.topViewController else { return nil }

        return if let navContoller = topViewController as? UINavigationController,
                  let topNavController = navContoller.topViewController
        {
            topNavController
        } else {
            topViewController
        }
    }

    init(_ customerServiceViewModel: CustomerServiceViewModel) {
        csViewModel = customerServiceViewModel
    }

    func initService() {
        Logger.shared.info("CustomerService init.")

        ballWindow = nil
        disposeBag = .init()
        addServiceIcon()

        bindFloatIconDisplayStatus()
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
                    height: 56
                ),
                viewModel: csViewModel
            )
        }
    }

    private func bindFloatIconDisplayStatus() {
        Driver.combineLatest(
            csViewModel.isPlayerInChat.asDriverOnErrorJustComplete(),
            floatIconAvailableRelay.asDriver()
        ) { ($0, $1) }
            .drive(onNext: { [ballWindow] in
                let (isPlayerInChat, floatIconAvailable) = $0
                let available = floatIconAvailable && isPlayerInChat

                ballWindow?.isHidden = !available
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
                guard
                    let roomID = status?.0,
                    let status = status?.1
                else { return }

                switch onEnum(of: status) {
                case .close:
                    Task { @MainActor in
                        ballWindow.isUserInteractionEnabled = false
                        if await csViewModel.hasExitSurvey(roomID) {
                            switchToExitSurvey(roomID)
                            try? await csViewModel.closeChatRoom().asCompletable().value
                        } else {
                            switchToChatRoom()
                        }
                        ballWindow.isUserInteractionEnabled = true
                    }
                case .connected:
                    switchToChatRoom()
                case .connecting:
                    switchToCalling()
                case .notExist:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    func setFloatIconAvailable(_ available: Bool) {
        floatIconAvailableRelay.accept(available)
    }

    func startCustomerService(from vc: UIViewController) -> Completable {
        csViewModel.hasPreChatSurvey()
            .observe(on: MainScheduler.instance)
            .do(onSuccess: { [unowned self] in
                if $0 {
                    switchToPrechat(from: vc)
                } else {
                    switchToCalling()
                }
            })
            .asCompletable()
            .catch { error in
                switch error {
                case is ServiceUnavailableException:
                    self.switchToCalling()
                    return Completable.empty()
                default:
                    return Completable.error(error)
                }
            }
    }

    private func switchToPrechat(from vc: UIViewController?) {
        let prechatVC = PrechatSurveyViewController()
        let navi = CustomServiceNavigationController(rootViewController: prechatVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        vc?.present(navi, animated: true, completion: nil)
    }

    private func switchToCalling() {
        let callingVC = CallingViewController(surveyAnswers: nil)
        let navi = CustomServiceNavigationController(rootViewController: callingVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        topViewController?.present(navi, animated: false, completion: nil)
    }

    private func switchToChatRoom() {
        let chatRoomVC = ChatRoomViewController()
        let navi = CustomServiceNavigationController(rootViewController: chatRoomVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        topViewController?.present(navi, animated: true, completion: nil)
    }

    private func switchToExitSurvey(_ roomID: String) {
        let exitSurveyVC = ExitSurveyViewController(roomID: roomID)
        let navi = CustomServiceNavigationController(rootViewController: exitSurveyVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        topViewController?.present(navi, animated: true, completion: nil)
    }

    func closeService() -> Completable {
        Logger.shared.info("Customer service status close.")

        return csViewModel.closeChatRoom(forceExit: true).asCompletable()
    }
}

extension UIViewController {
    static func getLastPresentedViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first { $0 is UIWindowScene } as? UIWindowScene
        let window = scene?.windows.first { $0.isKeyWindow }
        var presentedViewController = window?.rootViewController
        while presentedViewController?.presentedViewController != nil {
            presentedViewController = presentedViewController?.presentedViewController
        }
        return presentedViewController
    }
}
