import RxSwift
import SwiftUI

class WithdrawalCryptoLimitViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var viewModel: WithdrawalCryptoLimitViewModel

  private let disposeBag = DisposeBag()

  init(viewModel: WithdrawalCryptoLimitViewModel? = nil) {
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

extension WithdrawalCryptoLimitViewController {
  func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(vc: self, barItemType: .back)

    addSubView(
      WithdrawalCryptoLimitView(viewModel: viewModel)
        .environment(\.playerLocale, viewModel.getSupportLocale()),
      to: view)
  }

  func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }
}
