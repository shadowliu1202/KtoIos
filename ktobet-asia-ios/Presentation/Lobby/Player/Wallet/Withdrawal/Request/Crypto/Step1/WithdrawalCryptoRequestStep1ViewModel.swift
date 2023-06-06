import Combine
import Foundation
import RxCocoa
import RxSwift
import SharedBu

class WithdrawalCryptoRequestStep1ViewModel:
  CollectErrorViewModel,
  WithdrawalRequestVerifiable,
  WithdrawalCryptoRequestStep1ViewModelProtocol,
  ObservableObject
{
  @Published private(set) var cryptoWallet: WithdrawalDto.CryptoWallet?
  @Published private(set) var exchangeRateInfo: WithdrawalCryptoRequestDataModel.ExchangeRateInfo?
  @Published private(set) var requestInfo: WithdrawalCryptoRequestDataModel.RequestInfo?
  @Published private(set) var inputErrorText = ""
  @Published private(set) var submitButtonDisable = true
  @Published private(set) var outPutFiatAmount = ""
  @Published private(set) var outPutCryptoAmount = ""

  @Published var inputFiatAmount = ""
  @Published var inputCryptoAmount = ""

  private let withdrawalService: IWithdrawalAppService
  private let localStorageRepository: LocalStorageRepository

  private let disposeBag = DisposeBag()

  private lazy var localCurrency: AccountCurrency = getLocalCurrency()

  private var mergeFiatAmount = ""
  private var mergeCryptoAmount = ""
  private var cryptoExchangeRate = ObjectHelperKt
    .createExchangeRate(
      from: .eth,
      to: .Vietnam(),
      cryptoExchangeRate: "")

  lazy var supportLocale: SupportLocale = getSupportLocale()

  init(
    _ withdrawalService: IWithdrawalAppService,
    _ localStorageRepository: LocalStorageRepository)
  {
    self.withdrawalService = withdrawalService
    self.localStorageRepository = localStorageRepository
  }

  private func getLocalCurrency() -> AccountCurrency {
    localStorageRepository.getLocalCurrency()
  }

  private func getSupportLocale() -> SupportLocale {
    localStorageRepository.getSupportLocale()
  }

  func setup() {
    setupFiatAmountExchange()
    setupCryptoAmountExchange()
    setupAmountValidation()
  }

  func setupFiatAmountExchange() {
    $inputCryptoAmount
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        guard
          let cryptoWallet = self?.cryptoWallet,
          let fiatAmount = self?.cryptoExchangeRate
            .exchange(cryptoCurrency: $0.toCryptoCurrency(supportCryptoType: cryptoWallet.type))
        else {
          return
        }

        self?.outPutCryptoAmount = $0
        self?.outPutFiatAmount = $0.isNotEmpty ? fiatAmount.formatString(.none) : ""
      })
      .disposed(by: disposeBag)
  }

  func setupCryptoAmountExchange() {
    $inputFiatAmount
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        guard let cryptoAmount = self?.cryptoExchangeRate.exchange(accountCurrency: $0.toAccountCurrency())
        else { return }

        self?.outPutFiatAmount = $0
        self?.outPutCryptoAmount = $0.isNotEmpty ? cryptoAmount.formatString(.none) : ""
      })
      .disposed(by: disposeBag)
  }

  func setupAmountValidation() {
    Driver.of(
      $inputCryptoAmount.skipOneThenAsDriver(),
      $outPutCryptoAmount.skipOneThenAsDriver())
      .merge()
      .drive(onNext: { [weak self] in
        self?.mergeCryptoAmount = $0
      })
      .disposed(by: disposeBag)

    let fiatAmountMergeDriver = Driver.of(
      $inputFiatAmount.skipOneThenAsDriver(),
      $outPutFiatAmount.skipOneThenAsDriver())
      .merge()

    fiatAmountMergeDriver
      .drive(onNext: { [weak self] in
        self?.mergeFiatAmount = $0
      })
      .disposed(by: disposeBag)

    observeValidation(
      withdrawalService: withdrawalService,
      walletId: self.cryptoWallet?.walletId ?? "",
      amountDriver: fiatAmountMergeDriver)
      .subscribe(onNext: { [weak self] in
        self?.inputErrorText = $0 ?? ""
        self?.submitButtonDisable = $0?.isNotEmpty ?? true
      })
      .disposed(by: disposeBag)
  }

  func fetchExchangeRate(cryptoWallet: WithdrawalDto.CryptoWallet) {
    self.cryptoWallet = cryptoWallet

    Single.from(
      withdrawalService
        .getCryptoCurrencyExchangeRate(walletId: cryptoWallet.walletId))
      .subscribe(
        onSuccess: { [weak self] in
          self?.cryptoExchangeRate = $0
          self?.generateWithdrawalCryptoRequestDataModel(exchangeRate: $0, wallet: cryptoWallet)
        },
        onFailure: { [weak self] in
          self?.errorsSubject.onNext($0)
        })
      .disposed(by: disposeBag)
  }

  private func generateWithdrawalCryptoRequestDataModel(exchangeRate: IExchangeRate, wallet: WithdrawalDto.CryptoWallet) {
    let supportCrypto = wallet.type

    self.exchangeRateInfo = .init(
      icon: supportCrypto.icon,
      typeNetwork: "\(supportCrypto.name) \(wallet.network)",
      rate: exchangeRate.formatString(),
      ratio: "1 \(supportCrypto.name) = \(exchangeRate.formatString()) \(self.localCurrency.simpleName)")

    let cryptoCurrency = 0.toCryptoCurrency(supportCrypto)
    self.requestInfo = .init(
      fiat: localCurrency,
      crypto: cryptoCurrency,
      singleCashMinimum: wallet.limitation.oneOffMinimumAmount.formatString(),
      singleCashMaximum: wallet.limitation.oneOffMaximumAmount.formatString())
  }

  func autoFill(recipe: @escaping (WithdrawalDto.FulfillmentRecipe) -> Void) {
    Single.from(
      withdrawalService
        .calculateCryptoFulfillment(
          walletId: cryptoWallet?.walletId ?? "",
          exchangeRate: cryptoExchangeRate))
      .subscribe(onSuccess: {
        recipe($0)
      })
      .disposed(by: disposeBag)
  }

  func fillAmounts(accountCurrency: AccountCurrency, cryptoAmount: CryptoCurrency) {
    outPutFiatAmount = accountCurrency.formatString(.none)
    outPutCryptoAmount = cryptoAmount.formatString(.none)
  }

  func generateRequestConfirmModel() -> WithdrawalCryptoRequestConfirmDataModel.SetupModel? {
    guard
      let cryptoWallet,
      let exchangeRateInfo,
      let requestInfo
    else {
      return nil
    }

    return .init(
      cryptoWallet: cryptoWallet,
      cryptoAmount: mergeCryptoAmount,
      cryptoSimpleName: requestInfo.crypto.name,
      fiatAmount: mergeFiatAmount,
      fiatSimpleName: requestInfo.fiat.name,
      ratio: exchangeRateInfo.ratio)
  }
}
