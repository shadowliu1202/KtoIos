import RxSwift
import SharedBu

protocol WithdrawalCryptoWalletsViewModelProtocol: AnyObject {
  var supportLocale: SupportLocale { get }
  var playerWallet: WithdrawalDto.PlayerCryptoWallet? { get }
  var isUpToMaximum: Bool { get }
  var isEditing: Bool { get set }

  func observeWallets()
  func resetDisposeBag()
}

class WithdrawalCryptoWalletsViewModel:
  CollectErrorViewModel,
  WithdrawalCryptoWalletsViewModelProtocol,
  ObservableObject
{
  @Published private(set) var playerWallet: WithdrawalDto.PlayerCryptoWallet?

  @Published var isEditing = false

  private let withdrawalService: IWithdrawalAppService
  private var disposeBag = DisposeBag()

  let supportLocale: SupportLocale

  var isUpToMaximum: Bool {
    playerWallet?.wallets.count ?? 0 >= playerWallet?.maxAmount ?? 5
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
      withdrawalService.getCryptoWallets())
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

extension WithdrawalDto.CryptoWallet: WalletRowModel {
  var accountNumber: String {
    address
  }
}
