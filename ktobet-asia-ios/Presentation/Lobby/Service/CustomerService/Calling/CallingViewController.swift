import Lottie
import RxSwift
import sharedbu
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
  
  override func viewDidAppear(_ animation: Bool) {
    super.viewDidAppear(animation)
    
    csViewModel.chatRoomConnection
      .filter { $0 is sharedbu.Connection.StatusConnected }
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { _ in
          CustomServicePresenter.shared.switchToChatRoom(isRoot: false)
        })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    lottieView.addSubview(animationView, constraints: .fill())
    NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] _ in
        self?.animationView.play()
      })
      .disposed(by: disposeBag)
  }

  private func dataBinding() {
    csViewModel.currentQueueNumber
      .map { Localize.string("customerservice_chat_room_your_queue_number", "\($0)") }
      .bind(to: self.waitingCountLabel.rx.text)
      .disposed(by: self.disposeBag)
    
    connectChatRoom()
  }

  private func connectChatRoom() {
    Task {
      do {
        try await csViewModel.createChatRoom()
      }
      catch {
        handleError(error)
      }
    }
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
          .observe(on: MainScheduler.instance)
          .subscribe(
            onSuccess: { [weak self] _ in
              guard let self else { return }

              self.csViewModel.setupSurveyAnswer(answers: nil)
              self.stopServiceAndShowServiceOccupied()
            },
            onFailure: { [weak self] in
              self?.handleError($0)
            })
          .disposed(by: self.disposeBag)
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
