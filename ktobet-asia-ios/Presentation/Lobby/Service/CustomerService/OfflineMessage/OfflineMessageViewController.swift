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
  
  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  private func setupUI() {
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
      confirm: {
        CustomServicePresenter.shared.resetStatus()
      },
      cancel: nil)
  }
}

extension OfflineMessageViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    CustomServicePresenter.shared.resetStatus()
  }
}
