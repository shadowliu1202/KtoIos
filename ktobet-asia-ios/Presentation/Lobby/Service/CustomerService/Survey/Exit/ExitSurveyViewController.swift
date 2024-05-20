import Combine
import SwiftUI
import UIKit

final class ExitSurveyViewController: CommonViewController {
    @Injected private var viewModel: ExitSurveyViewModel
  
    private let roomID: String
  
    private var cancellables = Set<AnyCancellable>()
  
    init(roomID: String) {
        self.roomID = roomID
        super.init(nibName: nil, bundle: nil)
    }
  
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    var barButtonItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        binding()
    }
  
    private func setupUI() {
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
        bind(position: .right, barButtonItems: padding, skip)
        bind(position: .left, barButtonItems: .kto(.close))
    
        addSubView(
            from: { [unowned self] in
                ExitSurveyView(
                    viewModel: viewModel,
                    roomID: roomID,
                    onAnswerSubmitSuccess: { [unowned self] in
                        let presentingVC = navigationController?.presentingViewController
            
                        dismiss(animated: true) {
                            self.setNavigationManagement(presentingVC)
                            self.showSubmitSuccessToast(presentingVC)
                        }
                    })
            },
            to: view)
    }
  
    private func setNavigationManagement(_ presentingVC: UIViewController?) {
        NavigationManagement.sharedInstance.viewController = presentingVC
    }
  
    private func showSubmitSuccessToast(_ presentingVC: UIViewController?) {
        presentingVC?.showToast(
            Localize.string("customerservice_offline_survey_confirm_title"),
            barImg: .success)
    }
  
    private func binding() {
        viewModel.errors()
            .sink(receiveValue: { [unowned self] in handleErrors($0) })
            .store(in: &cancellables)
    }
}

extension ExitSurveyViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_: UIBarButtonItem) {
        let presentingVC = navigationController?.presentingViewController
    
        dismiss(animated: true) {
            self.setNavigationManagement(presentingVC)
        }
    }
  
    func pressedRightBarButtonItems(_: UIBarButtonItem) {
        let presentingVC = navigationController?.presentingViewController
    
        dismiss(animated: true) {
            self.setNavigationManagement(presentingVC)
        }
    }
}
