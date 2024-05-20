import Foundation
import RxCocoa
import RxSwift
import sharedbu

class WithdrawalCryptoRequestStep2ViewModel:
    CollectErrorViewModel,
    WithdrawalCryptoRequestStep2ViewModelProtocol,
    ObservableObject
{
    @Published private(set) var requestInfo: [DefaultRow.Common] = []
    @Published private(set) var afterInfo: [DefaultRow.Common] = []
    @Published private(set) var submitDisable = false

    private let withdrawalService: IWithdrawalAppService
    private let playerConfiguration: PlayerConfiguration

    private let disposeBag = DisposeBag()

    private var confirmRequest: WithdrawalCryptoRequestConfirmDataModel.ConfirmRequest?

    init(
        _ withdrawalService: IWithdrawalAppService,
        _ playerConfiguration: PlayerConfiguration)
    {
        self.withdrawalService = withdrawalService
        self.playerConfiguration = playerConfiguration
    }

    func setup(model: WithdrawalCryptoRequestConfirmDataModel.SetupModel?) {
        guard let model else {
            return
        }
        let confirmInfo = generateRequestConfirm(model: model)

        requestInfo = [
            item(
                key: "withdrawal_step2_title_1_tip",
                content: confirmInfo.cryptoCurrency),
            item(
                key: "cps_applied_network_address_title",
                content: confirmInfo.networkAddress),
            item(
                key: "cps_request_withdrawal_fiat_amount",
                content: confirmInfo.fiatCurrency),
            item(
                key: "cps_excahange_rate",
                content: confirmInfo.ratio)
        ]

        afterInfo = [
            item(
                key: "withdrawal_dailywithdrawalcount_2",
                content: Localize.string("common_times_count", confirmInfo.dailyCount)),
            item(
                key: "withdrawal_dailywithdrawalamount_2",
                content: confirmInfo.dailyAmount),
            item(
                key: "cps_remaining_crypto_requirement",
                content: confirmInfo.remainingRequirement)
        ]

        confirmRequest = confirmInfo.request
    }

    private func generateRequestConfirm(
        model: WithdrawalCryptoRequestConfirmDataModel
            .SetupModel)
        -> WithdrawalCryptoRequestConfirmDataModel
        .ConfirmInfo
    {
        .init(
            cryptoCurrency: "\(model.cryptoAmount) \(model.cryptoSimpleName)",
            networkAddress: "\(model.cryptoWallet.network) - \(model.cryptoWallet.address)",
            fiatCurrency: "\(model.fiatAmount) \(model.fiatSimpleName)",
            ratio: model.ratio,
            dailyCount: "\(model.cryptoWallet.limitation.currentCount - 1)",
            dailyAmount: "\(model.cryptoWallet.limitation.currentAmount - model.fiatAmount.toAccountCurrency())",
            remainingRequirement: "\(model.cryptoWallet.remainTurnOver.abs().formatString()) \(model.fiatSimpleName)",
            request: .init(
                walletId: model.cryptoWallet.walletId,
                fiatAmount: model.fiatAmount.replacingOccurrences(of: ",", with: ""),
                exchangedCryptoAmount: model.cryptoAmount))
    }

    private func item(key: String, content: String) -> DefaultRow.Common {
        .init(title: Localize.string(key), content: content)
    }

    func requestCryptoWithdrawalTo(_ onCompleted: @escaping () -> Void) {
        guard let confirmRequest else {
            return
        }

        Completable.from(
            withdrawalService.requestCryptoWithdrawalTo(
                walletId: confirmRequest.walletId,
                fiatAmount: confirmRequest.fiatAmount,
                exchangedCryptoAmount: confirmRequest.exchangedCryptoAmount))
            .do(
                onSubscribe: { [weak self] in
                    self?.submitDisable = true
                }, onDispose: { [weak self] in
                    self?.submitDisable = false
                })
            .subscribe(
                onCompleted: {
                    onCompleted()
                },
                onError: { [weak self] in
                    self?.errorsSubject
                        .onNext($0)
                })
            .disposed(by: disposeBag)
    }

    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }
}
