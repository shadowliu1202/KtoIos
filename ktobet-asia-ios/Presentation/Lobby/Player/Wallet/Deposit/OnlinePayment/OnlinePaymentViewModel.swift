import Foundation
import RxSwift
import sharedbu

class OnlinePaymentViewModel:
    OnlinePaymentViewModelProtocol &
    ObservableObject &
    CollectErrorViewModel
{
    @Published private(set) var remitMethodName = ""
    @Published private(set) var gateways: [OnlinePaymentDataModel.Gateway] = []

    @Published private(set) var remitterName = ""

    @Published private(set) var remitInfoErrorMessage: OnlinePaymentDataModel.RemittanceInfoError = .empty
    @Published private(set) var submitButtonDisable = true

    private var gatewayDTOs: [PaymentsDTO.Gateway] = []

    private let disposeBag = DisposeBag()

    private let playerDataUseCase: PlayerDataUseCase
    private let depositService: IDepositAppService
    private let httpClient: HttpClient
    private let playerConfiguration: PlayerConfiguration

    init(
        _ playerDataUseCase: PlayerDataUseCase,
        _ depositService: IDepositAppService,
        _ httpClient: HttpClient,
        _ playerConfiguration: PlayerConfiguration)
    {
        self.playerDataUseCase = playerDataUseCase
        self.depositService = depositService
        self.httpClient = httpClient
        self.playerConfiguration = playerConfiguration
    }

    func setupData(onlineDTO: PaymentsDTO.Online) {
        remitMethodName = onlineDTO.name

        RxSwift.Single.from(onlineDTO.beneficiaries)
            .map { $0 as! [PaymentsDTO.Gateway] }
            .map({ [weak self] gatewayDTOs in
                self?.gatewayDTOs = gatewayDTOs

                return gatewayDTOs
                    .map { DTO in
                        guard let cashType = self?.parseCashType(DTO.cash)
                        else { return nil }

                        return OnlinePaymentDataModel.Gateway(
                            id: DTO.identity,
                            name: DTO.name,
                            hint: DTO.hint,
                            remitType: DTO.remitType,
                            remitBanks: DTO.remitBank.map { $0.name },
                            cashType: cashType,
                            isAccountNumberDenied: DTO.isAccountNumberDenied,
                            isInstructionDisplayed: DTO.isInstructionDisplayed)
                    }
                    .compactMap { $0 }
            })
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] gatewayDMs in
                    self?.gateways = gatewayDMs
                },
                onFailure: { [weak self] error in
                    self?.errorsSubject.onNext(error)
                })
            .disposed(by: disposeBag)

        playerDataUseCase.getPlayerRealName()
            .subscribe(
                onSuccess: { [weak self] remitterName in
                    self?.remitterName = remitterName
                },
                onFailure: { [weak self] error in
                    self?.errorsSubject
                        .onNext(error)
                })
            .disposed(by: disposeBag)
    }

    private func parseCashType(_ cashType: CashType) -> OnlinePaymentDataModel.Gateway.CashType? {
        switch onEnum(of: cashType) {
        case .input(let it):
            return .input(
                limitation: (it.limitation.min.description(), it.limitation.max.description()),
                isFloatAllowed: it.isFloatAllowed)
        case .option(let it):
            return .option(amountList: it.list.map { $0.description })
        }
    }

    func verifyRemitInfo(info: OnlinePaymentDataModel.RemittanceInfo) {
        guard
            let selectedGatewayID = info.selectedGatewayID,
            let gatewayDTO = gatewayDTOs.first(
                where: { $0.identity == selectedGatewayID })
        else {
            submitButtonDisable = true
            return
        }

        let remitBankCodeDTO = gatewayDTO.remitBank
            .first(where: { $0.name == info.supportBankName })

        let remitApplication = RemitApplication(
            remitterName: info.remitterName,
            remitterAccount: info.remitterAccountNumber,
            remitterBankName: nil,
            remittance: info.remitAmount?.replacingOccurrences(of: ",", with: ""),
            supportBankCode: remitBankCodeDTO?.bankCode)

        remitInfoErrorMessage = toRemittanceInfoError(gatewayDTO, remitApplication)

        submitButtonDisable = !isInfoValid(gatewayDTO, remitApplication)
    }

    private func toRemittanceInfoError(
        _ gatewayDTO: PaymentsDTO.Gateway,
        _ remitApplication: RemitApplication)
        -> OnlinePaymentDataModel.RemittanceInfoError
    {
        let paymentErrors = gatewayDTO.verifier
            .verify(
                target: remitApplication,
                isIgnoreNull: true)

        return parsePaymentErrors(paymentErrors)
    }

    private func parsePaymentErrors(_ errors: [PaymentError]) -> OnlinePaymentDataModel.RemittanceInfoError {
        var remitterNameError = ""
        var remitterAccountNumberError = ""
        var remitAmountError = ""

        for error in errors {
            switch onEnum(of: error) {
            case .remittanceIsEmpty:
                remitAmountError = Localize.string("common_field_must_fill")
            case .remittanceOutOfRange:
                remitAmountError = Localize.string("deposit_limitation_hint")
            case .remitterAccountNeedDigitOnly:
                remitterAccountNumberError = Localize.string("common_field_format_incorrect")
            case .remitterNameExceededLength(let it):
                remitterNameError = Localize.string("register_name_format_error_length_limitation", "\(it.maxLength)")
            case .remitterNameIsEmpty:
                remitterNameError = Localize.string("common_field_must_fill")
            case .remittanceMalformed,
                 .remitterAccountNotNeeded,
                 .remitterBankIsEmpty,
                 .supportBankCodeIsEmpty:
                break
            }
        }

        return .init(
            remitterName: remitterNameError,
            remitterAccountNumber: remitterAccountNumberError,
            remitAmount: remitAmountError)
    }

    private func isInfoValid(
        _ gatewayDTO: PaymentsDTO.Gateway,
        _ remitApplication: RemitApplication)
        -> Bool
    {
        let paymentErrors = gatewayDTO.verifier
            .verify(
                target: remitApplication,
                isIgnoreNull: false)

        return paymentErrors.isEmpty
    }

    func submitRemittance(
        info: OnlinePaymentDataModel.RemittanceInfo,
        remitButtonOnSuccess: @escaping (_ url: String) -> Void)
    {
        guard
            let selectedGatewayID = info.selectedGatewayID,
            let gatewayDTO = gatewayDTOs.first(
                where: { $0.identity == selectedGatewayID })
        else {
            submitButtonDisable = true
            return
        }

        let onlineRemitApplication = createOnlineRemitApplication(gatewayDTO, info)
        let onlineRemitRequest = OnlineDepositDTO.Request(
            paymentIdentity: selectedGatewayID,
            application: onlineRemitApplication)

        Single.from(self.depositService.requestOnlineDeposit(request: onlineRemitRequest))
            .do(
                onSubscribe: { [weak self] in
                    self?.submitButtonDisable = true
                },
                onDispose: { [weak self] in
                    self?.submitButtonDisable = false
                })
            .subscribe(
                onSuccess: { [weak self] webPathDTO in
                    guard let self else { return }

                    let host = self.httpClient.host.absoluteString
                    let url = host + webPathDTO.path + "&backUrl=\(host)"

                    remitButtonOnSuccess(url)
                },
                onFailure: { [weak self] error in
                    self?.errorsSubject
                        .onNext(error)
                })
            .disposed(by: disposeBag)
    }

    func createOnlineRemitApplication(
        _ gatewayDTO: PaymentsDTO.Gateway,
        _ info: OnlinePaymentDataModel.RemittanceInfo)
        -> OnlineRemitApplication
    {
        let remitBankCodeDTO = gatewayDTO.remitBank
            .first(where: { $0.name == info.supportBankName })

        let onlineRemitter = OnlineRemitter(
            name: info.remitterName!,
            account: info.remitterAccountNumber)
        let remittance = info.remitAmount!.replacingOccurrences(of: ",", with: "")

        return .init(
            remitter: onlineRemitter,
            remittance: remittance,
            gatewayIdentity: gatewayDTO.identity,
            supportBankCode: remitBankCodeDTO?.bankCode)
    }

    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }

    func getTerminateAlertMessage() -> String {
        switch onEnum(of: playerConfiguration.supportLocale) {
        case .china:
            return Localize.string("deposit_online_terminate")
        case .vietnam:
            return Localize.string("deposit_payment_terminate", remitMethodName)
        }
    }
}
