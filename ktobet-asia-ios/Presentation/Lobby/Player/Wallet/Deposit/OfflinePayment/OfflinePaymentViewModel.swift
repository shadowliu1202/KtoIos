import Combine
import Foundation
import RxSwift
import sharedbu

class OfflinePaymentViewModel:
  CollectErrorViewModel, OfflinePaymentViewModelProtocol, ObservableObject
{
  @Published private(set) var gateways: [OfflinePaymentDataModel.Gateway] = []
  @Published private(set) var remitBankList: [String] = []
  @Published private(set) var remitterName = ""
  @Published private(set) var remitAmountLimitRange = ""

  @Published private(set) var remitInfoErrorMessage:
    OfflinePaymentDataModel.RemittanceInfoError =
    .init(
      bankName: "",
      remitterName: "",
      bankCardNumber: "",
      amount: "")

  @Published private(set) var submitButtonDisable = true

  private let depositService: IDepositAppService
  private let playerUseCase: PlayerDataUseCase
  private let playerConfiguration: PlayerConfiguration

  private let disposeBag = DisposeBag()

  private var bankCardDTOs = [PaymentsDTO.BankCard]()

  private var memoDTOResult: Result<OfflineDepositDTO.Memo, Error> = .failure(KTOError.EmptyData)

  init(
    _ depositService: IDepositAppService,
    _ playerUseCase: PlayerDataUseCase,
    _ playerConfiguration: PlayerConfiguration)
  {
    self.depositService = depositService
    self.playerUseCase = playerUseCase
    self.playerConfiguration = playerConfiguration
  }

  func fetchGatewayData() {
    let offlineDTOStream = RxSwift.Observable.from(depositService.getPayments())
      .compactMap { paymentsDTO in
        paymentsDTO.offline
      }
      .do(onError: { [weak self] error in
        self?.errorsSubject
          .onNext(error)
      })
      .share(replay: 1)

    getGateways(offlineDTOStream)
    getRemitAmountLimitRange(offlineDTOStream)
    getRemitBankList(offlineDTOStream)
  }

  private func getGateways(_ stream: Observable<PaymentsDTO.Offline>) {
    stream
      .flatMap { offlineDTO in
        RxSwift.Single.from(offlineDTO.beneficiaries)
      }
      .map { array in
        array as! [PaymentsDTO.BankCard]
      }
      .subscribe(onNext: { [weak self] bankCardDTOs in
        guard let self else { return }

        self.gateways = bankCardDTOs
          .map { bankCardDTO in
            OfflinePaymentDataModel.Gateway(
              id: bankCardDTO.identity,
              name: bankCardDTO.name,
              iconName: self.mapGatewayIconName(bankCardDTO.bankId))
          }

        self.bankCardDTOs = bankCardDTOs
      })
      .disposed(by: disposeBag)
  }

  private func mapGatewayIconName(_ bankId: String) -> String {
    switch playerConfiguration.supportLocale {
    case .China():
      return "CNY-\(bankId)"
    case .Vietnam():
      return "VND-\(bankId)"
    default:
      return "VND-\(bankId)"
    }
  }

  private func getRemitAmountLimitRange(_ stream: Observable<PaymentsDTO.Offline>) {
    stream
      .map { offlineDTO in
        String(
          format: Localize.string("deposit_offline_step1_tips"),
          offlineDTO.depositLimit.min.description(),
          offlineDTO.depositLimit.max.description())
      }
      .subscribe(onNext: { [weak self] amountLimitText in
        self?.remitAmountLimitRange = amountLimitText
      })
      .disposed(by: disposeBag)
  }

  private func getRemitBankList(_ stream: Observable<PaymentsDTO.Offline>) {
    stream
      .map { offlineDTO in
        offlineDTO.availableBank
          .map { bankDTO in
            bankDTO.name
          }
      }
      .subscribe(onNext: { [weak self] bankNames in
        self?.remitBankList = bankNames
      })
      .disposed(by: disposeBag)
  }

  func getRemitterName() {
    playerUseCase.getPlayerRealName()
      .subscribe(
        onSuccess: { [weak self] name in
          self?.remitterName = name
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  func verifyRemitInfo(info: OfflinePaymentDataModel.RemittanceInfo) {
    guard let gateway = bankCardDTOs.first(where: { $0.identity == info.selectedGatewayId })
    else { return }

    let paymentErrors = gateway.verifier.verify(
      target: RemitApplication(
        remitterName: info.remitterName,
        remitterAccount: info.bankCardNumber,
        remitterBankName: info.bankName,
        remittance: info.amount == nil ? nil : info.amount?.replacingOccurrences(of: ",", with: ""),
        supportBankCode: nil),
      isIgnoreNull: true)

    remitInfoErrorMessage = parsePaymentError(paymentErrors)

    createOfflineDepositMemo(info)
  }

  private func parsePaymentError(_ errors: [PaymentError]) -> OfflinePaymentDataModel.RemittanceInfoError {
    var bankNameError = ""
    var remitterNameError = ""
    var bankCardNumberError = ""
    var amountError = ""

    for error in errors {
      switch error {
      case is PaymentError.RemitterNameIsEmpty:
        remitterNameError = Localize.string("common_field_must_fill")

      case let error as PaymentError.RemitterNameExceededLength:
        remitterNameError = Localize.string("register_name_format_error_length_limitation", "\(error.maxLength)")

      case is PaymentError.RemitterBankIsEmpty:
        bankNameError = Localize.string("common_field_must_fill")

      case is PaymentError.RemitterAccountNeedDigitOnly:
        bankCardNumberError = Localize.string("common_field_format_incorrect")

      case is PaymentError.RemittanceOutOfRange:
        amountError = Localize.string("deposit_limitation_hint")

      case is PaymentError.RemittanceIsEmpty:
        amountError = Localize.string("common_field_must_fill")

      default:
        break
      }
    }

    return OfflinePaymentDataModel.RemittanceInfoError(
      bankName: bankNameError,
      remitterName: remitterNameError,
      bankCardNumber: bankCardNumberError,
      amount: amountError)
  }

  private func createOfflineDepositMemo(_ info: OfflinePaymentDataModel.RemittanceInfo) {
    guard
      let selectedGatewayId = info.selectedGatewayId,
      let remitterName = info.remitterName,
      let bankName = info.bankName,
      let amount = info.amount
    else {
      self.memoDTOResult = .failure(KTOError.EmptyData)
      return
    }

    let offlineRemitter = OfflineRemitter(
      name: remitterName,
      account: info.bankCardNumber,
      bankName: bankName)

    let offlineRemitApplication = OfflineRemitApplication(
      remitter: offlineRemitter,
      remittance: Int64(amount.replacingOccurrences(of: ",", with: "")) ?? 0,
      beneficiaryIdentity: selectedGatewayId)

    let offlineRequestDTO = OfflineDepositDTO.Request(application: offlineRemitApplication)

    if bankName.isEmpty || remitterName.isEmpty || amount.isEmpty {
      self.memoDTOResult = .failure(KTOError.EmptyData)
      self.submitButtonDisable = true
    }
    else {
      Observable.from(self.depositService.requestOfflineDeposit(request: offlineRequestDTO))
        .subscribe(
          onNext: { [weak self] memoDTO in
            self?.memoDTOResult = .success(memoDTO)
            self?.submitButtonDisable = false
          },
          onError: { [weak self] error in
            self?.memoDTOResult = .failure(error)
            self?.submitButtonDisable = true
          })
        .disposed(by: disposeBag)
    }
  }

  func submitRemittance(gatewayId: String?, onClick: @escaping (OfflineDepositDTO.Memo, PaymentsDTO.BankCard) -> Void) {
    switch memoDTOResult {
    case .success(let memoDTO):
      guard let bankCardDTO = bankCardDTOs.first(where: { $0.identity == gatewayId })
      else { return }

      onClick(memoDTO, bankCardDTO)
    case .failure:
      fatalError("should not reach here.")
    }
  }
}
