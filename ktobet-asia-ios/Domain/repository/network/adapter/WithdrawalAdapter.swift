import Foundation
import RxSwift
import SharedBu

class WithdrawalAdapter: WithdrawalProtocol {
  private let withdrawalAPI: WithdrawalAPI

  init(_ withdrawalAPI: WithdrawalAPI) {
    self.withdrawalAPI = withdrawalAPI
  }

  func deleteBankCard(bankCardId: String) -> CompletableWrapper {
    withdrawalAPI
      .deleteWithdrawalAccount(playerBankCardId: bankCardId)
      .asReaktiveCompletable()
  }

  func getBankCardCheck(
    bankId: Int32,
    bankName: String,
    accountNumber: String)
    -> SingleWrapper<ResponseItem<KotlinBoolean>>
  {
    withdrawalAPI
      .isWithdrawalAccountExist(
        bankId: bankId,
        bankName: bankName,
        accountNumber: accountNumber)
      .asReaktiveResponseItem()
  }

  func getCryptoWithdrawalPlayerCertification() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
    withdrawalAPI
      .isCryptoProcessCertified()
      .asReaktiveResponseItem()
  }

  func getWithdrawalBankCards() -> SingleWrapper<ResponseItem<WithdrawalBankCardBean>> {
    withdrawalAPI
      .getBankCard()
      .asReaktiveResponseItem(serial: WithdrawalBankCardBean.companion.serializer())
  }

  func getWithdrawalCryptoTransactionSuccessLog() -> SingleWrapper<ResponseItem<CryptoWithdrawalTransactionBean>> {
    withdrawalAPI
      .getWithdrawalCryptoTransactionSuccessLog()
      .asReaktiveResponseItem(serial: CryptoWithdrawalTransactionBean.companion.serializer())
  }

  func getWithdrawalDetail(displayId: String) -> SingleWrapper<ResponseItem<WithdrawalLogBeans.LogDetail>> {
    withdrawalAPI
      .getWithdrawalDetail(displayId: displayId)
      .asReaktiveResponseItem(serial: WithdrawalLogBeans.LogDetail.companion.serializer())
  }

  func getWithdrawalEachLimit() -> SingleWrapper<ResponseItem<WithdrawalEachLimitBean>> {
    withdrawalAPI
      .getWithdrawalEachLimit()
      .asReaktiveResponseItem(serial: WithdrawalEachLimitBean.companion.serializer())
  }

  func getWithdrawalIsApply() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
    withdrawalAPI
      .getIsAnyTicketApplying()
      .asReaktiveResponseItem()
  }

  func getWithdrawalLimitCount() -> SingleWrapper<ResponseItem<WithdrawalLimitCountBean>> {
    withdrawalAPI
      .getWithdrawalLimitCount()
      .asReaktiveResponseItem(serial: WithdrawalLimitCountBean.companion.serializer())
  }

  func getWithdrawalLogs(
    page: Int32,
    dateRangeBegin: String,
    dateRangeEnd: String,
    statusMap: [String: String]) -> SingleWrapper<ResponseList<WithdrawalLogBeans>>
  {
    withdrawalAPI
      .getWithdrawalLogs(
        page: Int(page),
        dateRangeBegin: dateRangeBegin,
        dateRangeEnd: dateRangeEnd,
        statusDictionary: statusMap)
      .asReaktiveResponseList(serial: WithdrawalLogBeans.companion.serializer())
  }

  func getWithdrawalTurnOver() -> SingleWrapper<ResponseItem<WithdrawalTurnOverBean>> {
    withdrawalAPI
      .getWithdrawalTurnOverRef()
      .asReaktiveResponseItem(serial: WithdrawalTurnOverBean.companion.serializer())
  }

  func getWithdrawals() -> SingleWrapper<ResponseList<WithdrawalLogBeans.LogBean>> {
    withdrawalAPI
      .getWithdrawals()
      .asReaktiveResponseList(serial: WithdrawalLogBeans.LogBean.companion.serializer())
  }

  func postBankCard(bean: BankCardBean) -> CompletableWrapper {
    withdrawalAPI
      .postBankCard(bean: bean)
      .asReaktiveCompletable()
  }

  func postWithdrawalBankCard(bean: WithdrawalBankCardRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
    withdrawalAPI
      .postWithdrawalToBankCard(bean: bean)
      .asReaktiveResponseItem()
  }

  func postWithdrawalCrypto(request: CryptoWithdrawalRequest) -> SingleWrapper<ResponseItem<NSString>> {
    withdrawalAPI
      .createCryptoWithdrawal(request: request)
      .asReaktiveResponseItem()
  }

  func putWithdrawalCancel(bean: WithdrawalCancelBean) -> CompletableWrapper {
    withdrawalAPI
      .putWithdrawalCancel(bean: bean)
      .asReaktiveCompletable()
  }

  func putWithdrawalImages(displayId: String, bean: WithdrawalImages) -> CompletableWrapper {
    withdrawalAPI
      .putWithdrawalImages(id: displayId, bean: bean)
      .asReaktiveCompletable()
  }
}
