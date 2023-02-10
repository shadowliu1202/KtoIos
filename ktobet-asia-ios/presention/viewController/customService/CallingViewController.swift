import UIKit
import Lottie
import RxSwift
import SharedBu

class CallingViewController: CommonViewController {
    var barButtonItems: [UIBarButtonItem] = []
    var csViewModel: CustomerServiceViewModel!
    var svViewModel: SurveyViewModel!
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var waitingCountLabel: UILabel!
    @IBOutlet weak var lottieView: UIView!
    
    private lazy var animationView: AnimationView = {
        let animationView = AnimationView()
        animationView.animation = Animation.named("cs_connection")
        animationView.frame = .zero
        animationView.center = self.lottieView.center
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        return animationView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CustomServicePresenter.shared.isInCallingView = false
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        lottieView.addSubview(animationView, constraints: .fill())
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).takeUntil(self.rx.deallocated).subscribe(onNext: { [weak self] _ in
            self?.animationView.play()
            CustomServicePresenter.shared.isInCallingView = true
        }).disposed(by: disposeBag)
    }
    
    private func dataBinding() {
        csViewModel.fullscreen().subscribe(onCompleted: {}).disposed(by: disposeBag)
        csViewModel.currentQueueNumber.map{ Localize.string("customerservice_chat_room_your_queue_number", "\($0)") }.bind(to: self.waitingCountLabel.rx.text).disposed(by: self.disposeBag)
        
        csViewModel.checkServiceAvailable()
            .subscribe(onSuccess: { [weak self] (isAvailable) in
            if !isAvailable {
                self?.stopServiceAndShowServiceOccupied()
            } else {
                self?.connectChatRoom()
            }
        }, onError: { [weak self] _ in
            self?.stopServiceAndShowServiceOccupied()
        }).disposed(by: disposeBag)
    }
    
    private func connectChatRoom() {
        svViewModel.cachedSurvey.flatMapLatest(csViewModel.connectChatRoom)
            .subscribe { status in
                switch status {
                case .connected:
                    Alert.shared.dismiss() {
                        CustomServicePresenter.shared.switchToChatRoom(isRoot: false)
                    }
                case .connecting:
                    print("connecting")
                case .closed:
                    print("close")
                case .notexist:
                    print("notexist")
                default:
                    break
                }
            } onError: { [weak self] error in
                self?.handleError(error)
            }.disposed(by: disposeBag)
    }
    
    private func handleError(_ e: Error) {
        switch e {
        case is ChatCheckGuestIPFail:
            stopServiceAndShowServiceOccupied()
        default:
            self.handleErrors(e)
        }
    }
    
    func confirmExitOrProceedToOfflineMessage() {
      Alert.shared.show(
        Localize.string("customerservice_stop_call_title"),
        Localize.string("customerservice_stop_call_content"),
        confirm: { },
        confirmText: Localize.string("common_continue"),
        cancel: { [weak self] in
          guard let self else { return }

          self.csViewModel
            .closeChatRoom()
            .subscribe(onCompleted: { [weak self] in
              guard let self else { return }

              self.csViewModel.setupSurveyAnswer(answers: nil)
            })
            .disposed(by: self.disposeBag)

          self.stopServiceAndShowServiceOccupied()
        },
        cancelText: Localize.string("common_stop"))
    }

    func stopServiceAndShowServiceOccupied() {
        Alert.shared.show(
            Localize.string("customerservice_leave_a_message_title"),
            Localize.string("customerservice_leave_a_message_content"),
            confirm: { [weak self] in CustomServicePresenter.shared.switchToOfflineMessage(from: self) },
            confirmText: Localize.string("customerservice_leave_a_message_confirm"),
            cancel: {
                CustomServicePresenter.shared.closeService()
                    .subscribe()
                    .disposed(by: self.disposeBag)
            },
            cancelText: Localize.string("common_skip")
        )
    }
}

extension CallingViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_ sender: UIBarButtonItem) {
        confirmExitOrProceedToOfflineMessage()
    }
}
