import Foundation
import RxCocoa
import RxSwift
import sharedbu

protocol WithdrawalAddFiatBankCardViewModelProtocol: AnyObject {
  var userName: String { get }
  var isRealNameEditable: Bool? { get }
  var bankNames: [String]? { get }
  var provinces: [String] { get }
  var countries: [String] { get }
  var bankError: String { get }
  var branchError: String { get }
  var provinceError: String { get }
  var cityError: String { get }
  var accountNumberError: String { get }
  var accountNumberMaxLength: Int { get }

  var selectedBank: String { set get }
  var inputBranch: String { set get }
  var selectedProvince: String { set get }
  var selectedCity: String { set get }
  var inputAccountNumber: String { set get }
  var isCitySelectorDisable: Bool { get }
  var isSubmitButtonDisable: Bool { get }

  func getSupportLocale() -> SupportLocale
  func setup()
  func addWithdrawalAccount(_ callback: @escaping () -> Void)
}

class WithdrawalAddFiatBankCardViewModel:
  CollectErrorViewModel,
  WithdrawalAddFiatBankCardViewModelProtocol,
  ObservableObject
{
  @Published private(set) var userName = ""
  @Published private(set) var isRealNameEditable: Bool?
  @Published private(set) var bankNames: [String]?
  @Published private(set) var provinces: [String] = []
  @Published private(set) var countries: [String] = []

  @Published private(set) var bankError = ""
  @Published private(set) var branchError = ""
  @Published private(set) var provinceError = ""
  @Published private(set) var cityError = ""
  @Published private(set) var accountNumberError = ""
  @Published private(set) var isSubmitButtonDisable = true
  @Published private var addWalletInProgress = false

  @Published var selectedBank = ""
  @Published var inputBranch = ""
  @Published var selectedProvince = ""
  @Published var selectedCity = ""
  @Published var inputAccountNumber = ""

  private let playerConfiguration: PlayerConfiguration
  private let authUseCase: AuthenticationUseCase
  private let bankAppService: BankAppService
  private let playerDataUseCase: PlayerDataUseCase
  private let accountPatternGenerator: AccountPatternGenerator
  private let appService: IWithdrawalAppService

  private let disposeBag = DisposeBag()

  private lazy var supportLocale: SupportLocale = getSupportLocale()
  private lazy var areaName: AreaNames = getAreaName()

  private var banks: [CommonDTO.Bank] = []

  var isCitySelectorDisable: Bool {
    selectedProvince.isEmpty || provinceError.isNotEmpty
  }

  lazy var accountNumberMaxLength = getAccountNumberMaxLength()

  init(
    _ playerConfiguration: PlayerConfiguration,
    _ authenticationUseCase: AuthenticationUseCase,
    _ bankAppService: BankAppService,
    _ playerDataUseCase: PlayerDataUseCase,
    _ accountPatternGenerator: AccountPatternGenerator,
    _ appService: IWithdrawalAppService)
  {
    self.playerConfiguration = playerConfiguration
    self.authUseCase = authenticationUseCase
    self.bankAppService = bankAppService
    self.playerDataUseCase = playerDataUseCase
    self.accountPatternGenerator = accountPatternGenerator
    self.appService = appService
  }

  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }

  private func getAreaName() -> AreaNames {
    AreaNameFactory.Companion().create(supportLocale: getSupportLocale())
  }

  private func getAccountNumberMaxLength() -> Int {
    Int(accountPatternGenerator.bankAccountNumber().lengthRange.last)
  }

  func setup() {
    setupCityRefreshing()

    setupBankValidation()
    setupBranchValidation()
    setupProvinceValidation()
    setupCityValidation()
    setupAccountNumberValidation()
    setupAllValidation()

    initUserName()
    initRealNameEditable()
    initBanks()
    initProvinces()
    initCountries()
  }

  private func setupCityRefreshing() {
    $selectedProvince
      .skipOneThenAsDriver()
      .distinctUntilChanged()
      .drive(onNext: { [weak self] _ in
        if self?.selectedCity != "" {
          self?.selectedCity = ""
        }
      })
      .disposed(by: disposeBag)
  }

  private func setupBankValidation() {
    $selectedBank
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        guard let self, let bankNames = self.bankNames else { return }
        self.bankError = self.accountPatternGenerator
          .bankName(banks: bankNames)
          .validate(name: $0)
          .localizeDescription
      })
      .disposed(by: disposeBag)
  }

  private func setupBranchValidation() {
    $inputBranch
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        guard let self else { return }
        self.branchError = self.accountPatternGenerator
          .bankBranch()
          .validate(name: $0)
          .localizeDescription
      })
      .disposed(by: disposeBag)
  }

  private func setupProvinceValidation() {
    $selectedProvince
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        self?.provinceError = $0.isEmpty ? Localize.string("common_field_must_fill") : ""
      })
      .disposed(by: disposeBag)
  }

  private func setupCityValidation() {
    $selectedCity
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        self?.cityError = $0.isEmpty ? Localize.string("common_field_must_fill") : ""
      })
      .disposed(by: disposeBag)
  }

  private func setupAccountNumberValidation() {
    $inputAccountNumber
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] in
        guard let self else { return }
        if self.inputAccountNumber.isEmpty {
          self.accountNumberError = Localize.string("common_field_must_fill")
        }
        else if !self.accountPatternGenerator.bankAccountNumber().verify(name: $0) {
          self.accountNumberError = Localize.string("common_invalid")
        }
        else {
          self.accountNumberError = ""
        }
      })
      .disposed(by: disposeBag)
  }

  private func setupAllValidation() {
    let validationObservables = Driver.combineLatest(
      $selectedBank.asDriver(),
      $inputBranch.asDriver(),
      $selectedProvince.asDriver(),
      $selectedCity.asDriver(),
      $inputAccountNumber.asDriver(),
      $accountNumberError.asDriver())
      .map {
        $0.0.isNotEmpty && $0.1.isNotEmpty && $0.2.isNotEmpty && $0.3.isNotEmpty && $0.4.isNotEmpty && $0.5.isEmpty
      }

    Driver.combineLatest(validationObservables, $addWalletInProgress.asDriver())
      .drive(onNext: { [weak self] in
        self?.isSubmitButtonDisable = !$0.0 || $0.1
      })
      .disposed(by: disposeBag)
  }

  private func initUserName() {
    userName = authUseCase.getUserName()
  }

  private func initRealNameEditable() {
    playerDataUseCase
      .isRealNameEditable()
      .collectError(to: self)
      .subscribe(
        onSuccess: { [weak self] in
          self?.isRealNameEditable = $0
        })
      .disposed(by: disposeBag)
  }

  private func initBanks() {
    Observable.from(bankAppService.getBanks())
      .map { $0 as! [CommonDTO.Bank] }
      .collectError(to: self)
      .subscribe(onNext: { [unowned self] in
        bankNames = $0.map { $0.name }
        banks = $0
      })
      .disposed(by: disposeBag)
  }

  private func initProvinces() {
    provinces = areaName.getProvinces().map { $0.name }
  }

  private func initCountries() {
    $selectedProvince
      .asDriver()
      .drive(onNext: { [weak self] in
        self?.countries = self?.areaName.getCities(province: Province(name: $0)).map { $0.name } ?? []
      })
      .disposed(by: disposeBag)
  }

  func addWithdrawalAccount(_ callback: @escaping () -> Void) {
    Single.from(
      appService
        .addFiatWallet(wallet: generateWalletFiatDTO()))
      .asCompletable()
      .do(
        onSubscribe: { [weak self] in
          self?.addWalletInProgress = true
        },
        onDispose: { [weak self] in
          self?.addWalletInProgress = false
        })
      .subscribe(
        onCompleted: {
          callback()
        }, onError: { [weak self] in
          self?.errorsSubject.onNext($0)
        })
      .disposed(by: disposeBag)
  }

  private func generateWalletFiatDTO() -> WithdrawalDto.NewWalletFiat {
    let bank = banks.first(where: { $0.name == selectedBank }) ?? CommonDTO.Bank.companion.unknown(name: selectedBank)

    return .init(
      bankName: bank.name,
      bankAccount: .init(
        bankId: bank.id,
        branch: inputBranch,
        accountName: self.userName,
        accountNumber: inputAccountNumber,
        city: selectedCity,
        location: selectedProvince))
  }
}
