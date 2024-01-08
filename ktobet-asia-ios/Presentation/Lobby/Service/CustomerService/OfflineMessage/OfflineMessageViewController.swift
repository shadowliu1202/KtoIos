import Combine
import SwiftUI
import UIKit

final class OfflineMessageViewController: CommonViewController {
  @Injected private var viewModel: OfflineMessageViewModel
  
  var barButtonItems: [UIBarButtonItem] = []
  
  private var cancellables = Set<AnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    binding()
  }
  
  private func setupUI() {
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
    bind(position: .right, barButtonItems: skip)
    
    addSubView(from: { [unowned self] in
      OfflineMessageView(
        viewModel: self.viewModel,
        submitOnComplete: { [unowned self] in surveySentSuccess() })
    }, to: view)
  }
  
  private func binding() {
    viewModel.errors()
      .sink(receiveValue: { [unowned self] in handleErrors($0) })
      .store(in: &cancellables)
  }
  
  private func surveySentSuccess() {
    Alert.shared.show(
      Localize.string("customerservice_offline_survey_confirm_title"),
      Localize.string("customerservice_offline_survey_confirm_content"),
      confirm: { [self] in
        dismissVC()
      },
      cancel: nil)
  }
  
  private func dismissVC() {
    let presentingVC = navigationController?.presentingViewController
    
    dismiss(animated: true) {
      NavigationManagement.sharedInstance.viewController = presentingVC
    }
  }
}

extension OfflineMessageViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    dismissVC()
  }
}
