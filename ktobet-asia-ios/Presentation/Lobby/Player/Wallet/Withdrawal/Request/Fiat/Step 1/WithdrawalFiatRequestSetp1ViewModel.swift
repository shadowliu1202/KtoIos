import RxSwift
import SharedBu

protocol WithdrawalFiatRequestStep1ViewModelProtocol: AnyObject {
  var supportLocale: SupportLocale { get }
  var wallet: WithdrawalDto.FiatWallet? { get }
  var amount: String { get set }
  var amountErrorText: String { get }
  var realNameInfo: (name: String, editable: Bool)? { get }
  var isAllowSubmit: Bool { get }

  func prepareForAppear(wallet: WithdrawalDto.FiatWallet)
}

class WithdrawalFiatRequestStep1ViewModel:
  CollectErrorViewModel,
  ObservableObject,
  WithdrawalRequestVerifiable,
  WithdrawalFiatRequestStep1ViewModelProtocol
{
  @Published private(set) var wallet: WithdrawalDto.FiatWallet?
  @Published private(set) var realNameInfo: (name: String, editable: Bool)?
  @Published private(set) var isAllowSubmit = false

  @Published private(set) var amountErrorText = ""
  @Published var amount = ""

  private let withdrawalService: IWithdrawalAppService
  private let playerDataUseCase: PlayerDataUseCase
  private let disposeBag = DisposeBag()

  let supportLocale: SupportLocale

  init(
    withdrawalService: IWithdrawalAppService,
    playerDataUseCase: PlayerDataUseCase,
    playerConfig: PlayerConfiguration)
  {
    self.withdrawalService = withdrawalService
    self.playerDataUseCase = playerDataUseCase
    self.supportLocale = playerConfig.supportLocale
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func prepareForAppear(wallet: WithdrawalDto.FiatWallet) {
    self.wallet = wallet

    Observable
      .combineLatest(
        playerDataUseCase.getPlayerRealName().asObservable(),
        playerDataUseCase.isRealNameEditable().asObservable())
      .map { (name: $0, editable: $1) }
      .publish(to: self, \.realNameInfo)
      .collectError(to: self)
      .subscribe()
      .disposed(by: disposeBag)

    observeValidation(
      withdrawalService: withdrawalService,
      walletId: self.wallet?.walletId ?? "",
      amountDriver: $amount.asDriver().skip(1))
      .subscribe(onNext: { [weak self] in
        self?.amountErrorText = $0 ?? ""
        self?.isAllowSubmit = $0?.isEmpty ?? false
      })
      .disposed(by: disposeBag)
  }
}
