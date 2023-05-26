import RxSwift
import SharedBu

protocol WithdrawalFiatWalletsViewModelProtocol: AnyObject {
  var supportLocale: SupportLocale { get }
  var playerWallet: WithdrawalDto.PlayerFiatWallet? { get }
  var isUpToMaximum: Bool { get }
  var isEditing: Bool { get set }

  func observeWallets()
  func resetDisposeBag()
}

class WithdrawalFiatWalletsViewModel:
  CollectErrorViewModel,
  WithdrawalFiatWalletsViewModelProtocol,
  ObservableObject
{
  @Published private(set) var playerWallet: WithdrawalDto.PlayerFiatWallet?

  @Published var isEditing = false

  private let withdrawalService: IWithdrawalAppService
  private var disposeBag = DisposeBag()

  let supportLocale: SupportLocale

  var isUpToMaximum: Bool {
    playerWallet?.wallets.count ?? 0 >= playerWallet?.maxAmount ?? 3
  }

  init(
    withdrawalService: IWithdrawalAppService,
    playerConfig: PlayerConfiguration)
  {
    self.withdrawalService = withdrawalService
    self.supportLocale = playerConfig.supportLocale
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func observeWallets() {
    Observable.from(
      withdrawalService.getFiatWallets())
      .publish(to: self, \.playerWallet)
      .collectError(to: self)
      .subscribe()
      .disposed(by: disposeBag)
  }

  func resetDisposeBag() {
    disposeBag = DisposeBag()
  }
}

// MARK: - Wallet Row Model

extension WithdrawalDto.FiatWallet: WalletRowModel {
  var accountNumber: String {
    bankAccount.accountNumber
  }
}
