import Combine
import sharedbu
import SwiftUI
import UIKit

class CallingViewController: CommonViewController {
  @Injected private var viewModel: CallingViewModel

  private var cancellables = Set<AnyCancellable>()
  
  var barButtonItems: [UIBarButtonItem] = []
  var surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?
  
  init(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) {
    self.surveyAnswers = surveyAnswers
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    binding()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    viewModel.getChatRoomStatus()
  }
  
  private func setupUI() {
    bind(position: .left, barButtonItems: .kto(.close))
    
    addSubView(from: { [unowned self] in
      CallingView(
        viewModel: viewModel,
        surveyAnswers: surveyAnswers)
    }, to: view)
  }
  
  private func binding() {
    viewModel.$chatRoomStatus
      .filter { $0 is sharedbu.Connection.StatusConnected }
      .sink { [unowned self] _ in
        toChatRoom()
      }
      .store(in: &cancellables)
    
    viewModel.$showLeaveMessageAlert
      .filter { $0 == true }
      .sink { [unowned self] _ in showLeaveMessageAlert() }
      .store(in: &cancellables)
    
    viewModel.errors()
      .sink(receiveValue: { [unowned self] in handleCallingErrors($0) })
      .store(in: &cancellables)
    
    viewModel.$isCloseEnable
      .sink(receiveValue: { [unowned self] in
        navigationItem.leftBarButtonItem?.isEnabled = $0
      })
      .store(in: &cancellables)
  }
  
  func toChatRoom() {
    CustomServicePresenter.shared.switchToChatRoom(isRoot: false)
  }
  
  private func handleCallingErrors(_ error: Error) {
    switch error {
    case is ChatCheckGuestIPFail,
         is ChatRoomNotExist,
         is ServiceUnavailableException:
      showStopCallingAlert()
    case is ChatRoomIsCreated:
      break
    default:
      handleErrors(error)
    }
  }
  
  func showStopCallingAlert() {
    Alert.shared.show(
      Localize.string("customerservice_stop_call_title"),
      Localize.string("customerservice_stop_call_content"),
      confirm: { },
      confirmText: Localize.string("common_continue"),
      cancel: { [unowned self] in
        guard let _ = CustomServicePresenter.shared.topViewController as? CallingViewController else { return }
        viewModel.closeChatRoom()
      },
      cancelText: Localize.string("common_stop"))
  }
  
  func showLeaveMessageAlert() {
    Alert.shared.show(
      Localize.string("customerservice_leave_a_message_title"),
      Localize.string("customerservice_leave_a_message_content"),
      confirm: { [unowned self] in
        let presentingVC = navigationController?.presentingViewController
        dismiss(animated: false) { [unowned self] in
          toOfflineMessageVC(presentingVC)
        }
      },
      confirmText: Localize.string("customerservice_leave_a_message_confirm"),
      cancel: { [unowned self] in
        dismiss(animated: true)
      },
      cancelText: Localize.string("common_skip"))
  }
  
  func toOfflineMessageVC(_ presentingVC: UIViewController?) {
    let to = OfflineMessageViewController()
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
    to.bind(position: .right, barButtonItems: skip)
    let navi = UINavigationController(rootViewController: to)
    navi.modalPresentationStyle = .fullScreen
    presentingVC?.present(navi, animated: false)
  }
}

extension CallingViewController: BarButtonItemable {
  func pressedLeftBarButtonItems(_: UIBarButtonItem) {
    showStopCallingAlert()
  }
}
