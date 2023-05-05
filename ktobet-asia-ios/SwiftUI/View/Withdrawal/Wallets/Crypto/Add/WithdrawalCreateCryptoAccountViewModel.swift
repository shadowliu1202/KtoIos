import Combine
import RxCocoa
import RxSwift
import SharedBu

extension WithdrawalCreateCryptoAccountViewModel {
  enum AddressVerifyStatus {
    case valid
    case mustFill
    case malformedInputERC20
    case malformedInputTRC20

    var errorText: String {
      switch self {
      case .valid:
        return ""
      case .mustFill:
        return Localize.string("common_field_must_fill")
      case .malformedInputERC20:
        return Localize.string("cps_erc20_address_error")
      case .malformedInputTRC20:
        return Localize.string("cps_trc20_address_error")
      }
    }
  }

  enum AliasVerifyStatus {
    case valid
    case mustFill

    var errorText: String {
      switch self {
      case .valid:
        return ""
      case .mustFill:
        return Localize.string("common_field_must_fill")
      }
    }
  }
}

class WithdrawalCreateCryptoAccountViewModel:
  WithdrawalCreateCryptoAccountViewModelProtocol &
  ObservableObject &
  CollectErrorViewModel
{
  @Published private(set) var cryptoTypes: [String] = []
  @Published private(set) var cryptoNetworks: [String] = []

  @Published private(set) var addressVerifyErrorText = ""
  @Published private(set) var aliasVerifyErrorText = ""

  @Published private(set) var isCreateAccountEnable = false

  @Published private(set) var isLoading = true

  @Published var selectedCryptoType = ""
  @Published var selectedCryptoNetwork = ""

  @Published var accountAlias = ""
  @Published var accountAddress = ""

  @Published private var isAddWalletInProgress = false
  @Published private var isInputValid = false

  private let withdrawalAppService: IWithdrawalAppService
  private let playerConfiguration: PlayerConfiguration

  private let disposeBag = DisposeBag()

  private var supportCryptoTypes: [SupportCryptoType] = []
  private var supportCryptoNetworks: [CryptoNetwork] = []

  init(
    _ withdrawalAppService: IWithdrawalAppService,
    _ playerConfiguration: PlayerConfiguration)
  {
    self.withdrawalAppService = withdrawalAppService
    self.playerConfiguration = playerConfiguration
  }

  func setup() {
    setupCryptoNetworksRefreshing()
    setupSelectedCryptoNetworkRefreshing()
    setupAddressValidation()
    setupAliasValidation()
    setupCreateAccountInputValid()
    setupCreateAccountEnable()

    initCryptoTypes()
    initAccountAlias()
  }

  private func setupCryptoNetworksRefreshing() {
    $selectedCryptoType
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] cryptoTypeName in
        guard let self else { return }
        let supportCryptoNetworks = self.supportCryptoTypes
          .first(where: { $0.name == cryptoTypeName })!
          .supportNetwork()

        self.cryptoNetworks = supportCryptoNetworks.map { $0.name }
        self.supportCryptoNetworks = supportCryptoNetworks
      })
      .disposed(by: disposeBag)
  }

  private func setupSelectedCryptoNetworkRefreshing() {
    $cryptoNetworks
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] cryptoNetworkNames in
        guard
          !cryptoNetworkNames
            .contains(where: { $0 == self?.selectedCryptoNetwork })
        else { return }

        self?.selectedCryptoNetwork = self?.cryptoNetworks.first ?? ""
      })
      .disposed(by: disposeBag)
  }

  private func setupAddressValidation() {
    Driver.combineLatest(
      $selectedCryptoNetwork.skipOneThenAsDriver(),
      $accountAddress.skipOneThenAsDriver())
      .drive(onNext: { [weak self] cryptoNetworkName, address in
        guard
          let self,
          let cryptoNetwork = self.supportCryptoNetworks
            .first(where: { $0.name == cryptoNetworkName })
        else { return }

        self.addressVerifyErrorText = self.parseErrorText(network: cryptoNetwork, address: address)
      })
      .disposed(by: disposeBag)
  }

  private func parseErrorText(network: CryptoNetwork, address: String) -> String {
    guard address.isNotEmpty
    else {
      return AddressVerifyStatus.mustFill.errorText
    }

    guard network.isValid(cryptoNetworkAddress: address)
    else {
      switch network {
      case .erc20:
        return AddressVerifyStatus.malformedInputERC20.errorText
      case .trc20:
        return AddressVerifyStatus.malformedInputTRC20.errorText
      default:
        fatalError("should not reach here.")
      }
    }

    return AddressVerifyStatus.valid.errorText
  }

  private func setupAliasValidation() {
    $accountAlias
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] accountAlias in
        self?.aliasVerifyErrorText = accountAlias.isEmpty
          ? AliasVerifyStatus.mustFill.errorText
          : AliasVerifyStatus.valid.errorText
      })
      .disposed(by: disposeBag)
  }

  private func setupCreateAccountInputValid() {
    Driver.combineLatest(
      $aliasVerifyErrorText.receive(on: RunLoop.main).skipOneThenAsDriver(),
      $addressVerifyErrorText.receive(on: RunLoop.main).skipOneThenAsDriver())
      .drive(onNext: { [weak self] addressErrorText, aliasErrorText in
        self?.isInputValid = addressErrorText.isEmpty && aliasErrorText.isEmpty
      })
      .disposed(by: disposeBag)
  }

  private func setupCreateAccountEnable() {
    Driver.combineLatest(
      $isAddWalletInProgress.receive(on: RunLoop.main).asDriver(),
      $isInputValid.receive(on: RunLoop.main).skipOneThenAsDriver())
      .drive(onNext: { [weak self] isAddWalletInProgress, isInputValid in
        self?.isCreateAccountEnable = !isAddWalletInProgress && isInputValid
      })
      .disposed(by: disposeBag)
  }

  private func initCryptoTypes() {
    supportCryptoTypes = withdrawalAppService.getWalletSupportCryptoTypes()
    cryptoTypes = supportCryptoTypes.map { $0.name }
    selectedCryptoType = cryptoTypes.first ?? ""
  }

  private func initAccountAlias() {
    Observable.from(
      withdrawalAppService
        .getCryptoWallets())
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] playerCryptoWalletDTO in
          let existingAccountCount = playerCryptoWalletDTO.wallets.count
          self?.accountAlias = Localize.string("cps_default_bank_card_name") + "\(existingAccountCount + 1)"
          self?.isLoading = false
        },
        onError: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  func readQRCode(image: UIImage?, onFailure: (() -> Void)? = nil) {
    if
      let features = detectQRCode(image),
      !features.isEmpty
    {
      for case let row as CIQRCodeFeature in features {
        accountAddress = row.messageString ?? ""
      }
    }
    else {
      onFailure?()
    }
  }

  private func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
    guard
      let image,
      let ciImage = CIImage(image: image)
    else {
      return nil
    }

    var options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]

    let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: options)

    if ciImage.properties.keys.contains(kCGImagePropertyOrientation as String) {
      options = [CIDetectorImageOrientation: ciImage.properties[kCGImagePropertyOrientation as String] ?? 1]
    }
    else {
      options = [CIDetectorImageOrientation: 1]
    }

    let features = qrDetector?.features(in: ciImage, options: options)
    return features
  }

  func createCryptoAccount(onSuccess: ((_ bankCardId: String) -> Void)?) {
    let newCryptoWallet = WithdrawalDto.NewWalletCrypto(
      alias: accountAlias,
      cryptoType: supportCryptoTypes.first(where: { $0.name == selectedCryptoType })!,
      walletAddress: accountAddress,
      cryptoNetwork: supportCryptoNetworks.first(where: { $0.name == selectedCryptoNetwork })!)

    Single.from(
      withdrawalAppService
        .addCryptoWallet(wallet: newCryptoWallet))
      .do(
        onSubscribe: { [weak self] in
          self?.isAddWalletInProgress = true
        },
        onDispose: { [weak self] in
          self?.isAddWalletInProgress = false
        })
      .subscribe(
        onSuccess: { bankCardID in
          onSuccess?(String(bankCardID))
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
