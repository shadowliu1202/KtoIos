import Foundation
import RxSwift
import sharedbu

class WithdrawalAdapter: WithdrawalProtocol {
    private let withdrawalAPI: WithdrawalAPI

    init(_ withdrawalAPI: WithdrawalAPI) {
        self.withdrawalAPI = withdrawalAPI
    }

    func deleteBankCard(bankCardId: String) -> CompletableWrapper {
        withdrawalAPI.deleteWithdrawalAccount(playerBankCardId: bankCardId)
    }

    func getBankCardCheck(bankId: Int32, bankName: String, accountNumber: String) -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        withdrawalAPI.isWithdrawalAccountExist(
            bankId: bankId,
            bankName: bankName,
            accountNumber: accountNumber
        )
    }

    func getCryptoWithdrawalPlayerCertification() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        withdrawalAPI.isCryptoProcessCertified()
    }

    func getWithdrawalBankCards() -> SingleWrapper<ResponseItem<WithdrawalBankCardBean>> {
        withdrawalAPI.getBankCard()
    }

    func getWithdrawalCryptoTransactionSuccessLog() -> SingleWrapper<ResponseItem<CryptoWithdrawalTransactionBean>> {
        withdrawalAPI.getWithdrawalCryptoTransactionSuccessLog()
    }

    func getWithdrawalDetail(displayId: String) -> SingleWrapper<ResponseItem<WithdrawalLogBeans.LogDetail>> {
        withdrawalAPI.getWithdrawalDetail(displayId: displayId)
    }

    func getWithdrawalEachLimit() -> SingleWrapper<ResponseItem<WithdrawalEachLimitBean>> {
        withdrawalAPI.getWithdrawalEachLimit()
    }

    func getWithdrawalIsApply() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        withdrawalAPI.getIsAnyTicketApplying()
    }

    func getWithdrawalLimitCount() -> SingleWrapper<ResponseItem<WithdrawalLimitCountBean>> {
        withdrawalAPI.getWithdrawalLimitCount()
    }

    func getWithdrawalLogs(
        page: Int32,
        dateRangeBegin: String,
        dateRangeEnd: String,
        statusMap: [String: String]
    ) -> SingleWrapper<ResponseList<WithdrawalLogBeans>> {
        withdrawalAPI.getWithdrawalLogs(
            page: Int(page),
            dateRangeBegin: dateRangeBegin,
            dateRangeEnd: dateRangeEnd,
            statusDictionary: statusMap
        )
    }

    func getWithdrawalTurnOver() -> SingleWrapper<ResponseItem<WithdrawalTurnOverBean>> {
        withdrawalAPI.getWithdrawalTurnOverRef()
    }

    func getWithdrawals() -> SingleWrapper<ResponseList<WithdrawalLogBeans.LogBean>> {
        withdrawalAPI.getWithdrawals()
    }

    func postBankCard(bean: BankCardBean) -> CompletableWrapper {
        withdrawalAPI.postBankCard(bean: bean)
    }

    func postWithdrawalBankCard(bean: WithdrawalBankCardRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
        withdrawalAPI.postWithdrawalToBankCard(bean: bean)
    }

    func postWithdrawalCrypto(request: CryptoWithdrawalRequest) -> SingleWrapper<ResponseItem<NSString>> {
        withdrawalAPI.createCryptoWithdrawal(request: request)
    }

    func putWithdrawalCancel(bean: WithdrawalCancelBean) -> CompletableWrapper {
        withdrawalAPI.putWithdrawalCancel(bean: bean)
    }

    func putWithdrawalImages(displayId: String, bean: WithdrawalImages) -> CompletableWrapper {
        withdrawalAPI.putWithdrawalImages(id: displayId, bean: bean)
    }
}
