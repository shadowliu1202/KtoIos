import RxSwift
import SharedBu

protocol WithdrawalFiatRequestStep2ViewModelProtocol: AnyObject {
  var supportLocale: SupportLocale { get }
  var wallet: WithdrawalDto.FiatWallet? { get }
  var amount: String { get }
  var isRealNameEditable: Bool { get }
  var isSubmitSuccess: Bool { get }
  var isSubmitDisable: Bool { get }

  func prepareForAppear(wallet: WithdrawalDto.FiatWallet, amount: String)

  func submitWithdrawal()
}

class WithdrawalFiatRequestStep2ViewModel:
  CollectErrorViewModel,
  ObservableObject,
  WithdrawalFiatRequestStep2ViewModelProtocol
{
  @Injected private var loading: Loading

  @Published private(set) var wallet: WithdrawalDto.FiatWallet?
  @Published private(set) var amount = ""
  @Published private(set) var isSubmitSuccess = false
  @Published private(set) var isSubmitDisable = false

  private let withdrawalService: IWithdrawalAppService
  private let disposeBag = DisposeBag()

  let supportLocale: SupportLocale

  var isRealNameEditable = false

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

  func prepareForAppear(wallet: WithdrawalDto.FiatWallet, amount: String) {
    self.wallet = wallet
    self.amount = amount
  }
}

// MARK: - API

extension WithdrawalFiatRequestStep2ViewModel {
  func submitWithdrawal() {
    Single.from(
      withdrawalService
        .requestFiatWithdrawalTo(
          walletId: wallet?.walletId ?? "",
          amount: amount.toAccountCurrency()))
      .do(
        onSubscribe: { [weak self] in
          self?.isSubmitDisable = true
        },
        onDispose: { [weak self] in
          self?.isSubmitDisable = false
        })
      .map { _ in true }
      .subscribe(
        onSuccess: { [weak self] in
          self?.isSubmitSuccess = $0
        },
        onFailure: { [weak self] in
          self?.errorsSubject.onNext($0)
        })
      .disposed(by: disposeBag)
  }
}
