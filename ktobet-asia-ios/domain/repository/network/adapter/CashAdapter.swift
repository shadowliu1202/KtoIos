import Foundation
import SharedBu

class CashAdapter: CashProtocol {
    private var playerAPI: PlayerApi!
    
    init(_ playerAPI: PlayerApi) {
        self.playerAPI = playerAPI
    }
    
    func getCashTransactionSummary(begin: String, end: String, balanceLogFilterType: Int32) -> SingleWrapper<ResponseItem<CashTransactionSummaryBean>> {
        playerAPI.getCashLogSummary1(begin: begin, end: end, balanceLogFilterType: Int(balanceLogFilterType)).asReaktiveResponseItem(serial: CashTransactionSummaryBean.companion.serializer())
    }
}
