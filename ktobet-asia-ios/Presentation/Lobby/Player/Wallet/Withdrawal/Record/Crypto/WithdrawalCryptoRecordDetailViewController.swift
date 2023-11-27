import RxSwift
import sharedbu
import UIKit

class WithdrawalCryptoRecordDetailViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var viewModel: WithdrawalCryptoRecordDetailViewModel

  private let displayId: String
  private let disposeBag = DisposeBag()

  init(
    displayId: String,
    viewModel: WithdrawalCryptoRecordDetailViewModel? = nil)
  {
    self.displayId = displayId

    if let viewModel {
      self._viewModel.wrappedValue = viewModel
    }

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
}

// MARK: - UI

extension WithdrawalCryptoRecordDetailViewController {
  private func setupUI() {
    addSubView(
      from: { [unowned self] in
        WithdrawalCryptoRecordDetailView(
          viewModel: self.viewModel,
          displayId: displayId)
      },
      to: view)
  }

  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }
}
