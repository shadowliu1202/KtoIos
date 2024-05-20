import Combine
import sharedbu
import SwiftUI
import UIKit

class CallingViewController: CommonViewController {
    @Injected private var viewModel: CallingViewModel

    private let loadingView: UIView = UIHostingController(rootView: SwiftUILoadingView(backgroundOpacity: 0.8)).view
  
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
  
    private func setupUI() {
        bind(position: .left, barButtonItems: .kto(.close))
        setupLoadingView()
    
        addSubView(from: { [unowned self] in
            CallingView(
                viewModel: viewModel,
                surveyAnswers: surveyAnswers)
        }, to: view)
    }
  
    private func setupLoadingView() {
        loadingView.backgroundColor = .clear
        navigationController?.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    
        loadingView.isHidden = true
    }
  
    private func binding() {
        viewModel.getChatRoomStream()
            .filter { $0.status is sharedbu.Connection.StatusConnected }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                toChatRoom()
            }
            .store(in: &cancellables)
    
        viewModel.errors()
            .sink(receiveValue: { [unowned self] in handleCallingErrors($0) })
            .store(in: &cancellables)
    }
  
    func toChatRoom() {
        navigationController?.setViewControllers([ChatRoomViewController()], animated: false)
    }
  
    private func handleCallingErrors(_ error: Error) {
        switch error {
        case is ChatCheckGuestIPFail,
             is ChatRoomNotExist,
             is ServiceUnavailableException:
            showLeaveMessageAlert()
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
            cancel: {
                guard let _ = CustomServicePresenter.shared.topViewController as? CallingViewController else { return }
        
                Task { [weak self] in
                    do {
                        self?.enableLoading(true)
                        try await self?.viewModel.closeChatRoom()
                        self?.enableLoading(false)
                        self?.showLeaveMessageAlert()
                    }
                    catch {
                        self?.enableLoading(false)
                        self?.handleCallingErrors(error)
                    }
                }
            },
            cancelText: Localize.string("common_stop"))
    }
  
    func enableLoading(_ isEnabled: Bool) {
        loadingView.isHidden = !isEnabled
        navigationItem.leftBarButtonItem?.isEnabled = !isEnabled
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
