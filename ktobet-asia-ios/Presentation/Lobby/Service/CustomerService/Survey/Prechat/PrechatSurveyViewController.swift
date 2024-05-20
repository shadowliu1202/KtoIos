import Combine
import sharedbu
import SwiftUI
import UIKit

final class PrechatSurveyViewController: CommonViewController {
    @Injected private var viewModel: PrechatSurveyViewModel
  
    private var cancellables = Set<AnyCancellable>()
  
    var barButtonItems: [UIBarButtonItem] = []
  
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        binding()
    }
  
    private func setupUI() {
        let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
        let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip"))).senderId(skipBarBtnId)
        bind(position: .left, barButtonItems: .kto(.close))
        bind(position: .right, barButtonItems: padding, skip)
    
        addSubView(
            from: { [unowned self] in
                PrechatSurveyView(
                    viewModel: viewModel,
                    submitButtonOnTap: { [unowned self] in toCalling($0) })
            },
            to: view)
    }
  
    private func binding() {
        viewModel.errors()
            .sink(receiveValue: { [unowned self] in handleErrors($0) })
            .store(in: &cancellables)
    
        viewModel.$isSubmitButtonDisable
            .sink(receiveValue: { [unowned self] in
                barButtonItems.first(where: { $0.tag == skipBarBtnId })?.isEnabled = !$0
            })
            .store(in: &cancellables)
    }
  
    private func toCalling(_ surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) {
        let callingVC = CallingViewController(surveyAnswers: surveyAnswers)
        navigationController?.setViewControllers([callingVC], animated: false)
    }
}

extension PrechatSurveyViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_: UIBarButtonItem) {
        dismiss(animated: true)
    }
  
    func pressedRightBarButtonItems(_: UIBarButtonItem) {
        toCalling(nil)
    }
}
