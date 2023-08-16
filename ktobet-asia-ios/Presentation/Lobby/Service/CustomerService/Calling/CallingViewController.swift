import Lottie
import RxSwift
import SharedBu
import UIKit

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
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    lottieView.addSubview(animationView, constraints: .fill())
    NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] _ in
        self?.animationView.play()
        CustomServicePresenter.shared.isInCallingView = true
      }).disposed(by: disposeBag)
  }

  private func dataBinding() {
    csViewModel.fullscreen()
      .subscribe(onCompleted: { })
      .disposed(by: disposeBag)
    
    csViewModel.currentQueueNumber
      .map { Localize.string("customerservice_chat_room_your_queue_number", "\($0)") }
      .bind(to: self.waitingCountLabel.rx.text)
      .disposed(by: self.disposeBag)
    
    connectChatRoom()
  }

  private func connectChatRoom() {
    csViewModel
      .currentChatRoom()
      .take(1)
      .flatMap { [weak self] chatRoomDTO -> Completable in
        guard let self else { throw KTOError.LostReference }
        
        if chatRoomDTO.status == SharedBu.Connection.StatusNotExist() {
          return self.csViewModel.connectChatRoom()
        }
        else {
          return Observable.just(()).asSingle().asCompletable()
        }
      }
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .observe(on: MainScheduler.instance)
      .subscribe(onError: { [weak self] error in
        self?.handleError(error)
      })
      .disposed(by: disposeBag)
    
    csViewModel.chatRoomConnection
      .filter { $0 is SharedBu.Connection.StatusConnected }
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { _ in
          CustomServicePresenter.shared.switchToChatRoom(isRoot: false)
        })
      .disposed(by: disposeBag)
  }

  private func handleError(_ e: Error) {
    switch e {
    case is ChatCheckGuestIPFail,
         is ChatRoomNotExist,
         is ServiceUnavailableException:
      
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
          .subscribe(onSuccess: { [weak self] _ in
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
        CustomServicePresenter.shared.resetStatus()
      },
      cancelText: Localize.string("common_skip"))
  }
}

extension CallingViewController: BarButtonItemable {
  func pressedLeftBarButtonItems(_: UIBarButtonItem) {
    confirmExitOrProceedToOfflineMessage()
  }
}
