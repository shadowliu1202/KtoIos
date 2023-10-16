import Combine
import SwiftUI
import UIKit

final class OfflineMessageViewController: CommonViewController {
  var barButtonItems: [UIBarButtonItem] = []
  
  private var viewModel: OfflineMessageViewModel
  private var cancellables = Set<AnyCancellable>()
  
  init(viewModel: OfflineMessageViewModel) {
    self.viewModel = viewModel
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
  
  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  private func setupUI() {
    view.backgroundColor = .greyScaleDefault
    
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
