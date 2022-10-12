import Foundation
import SharedBu
import RxSwift

typealias HtmlString = String
protocol TransactionLogUseCase {
    func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]>
    func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary>
    func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail>
    func getCasinoWagerDetail(wagerId: String) -> Single<HtmlString>
    func getSportsBookWagerDetail(wagerId: String) -> Single<HtmlString>
}

class TransactionLogUseCaseImpl: TransactionLogUseCase {
    var transactionLogRepository : TransactionLogRepository!
    var playerRepository : PlayerRepository!
    
    init(_ transactionLogRepository : TransactionLogRepository, _ playerRepository : PlayerRepository) {
        self.transactionLogRepository = transactionLogRepository
        self.playerRepository = playerRepository
    }
    
    func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]> {
        transactionLogRepository.searchTransactionLog(from: from, to: to, BalanceLogFilterType: BalanceLogFilterType, page: page)
    }
    
    func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary> {
        transactionLogRepository.getCashFlowSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType)
    }
    
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary> {
        transactionLogRepository.getCashLogSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType)
    }
    
    func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
        return transactionLogRepository.getBalanceLogDetail(transactionId: transactionId)
    }
    
    func getCasinoWagerDetail(wagerId: String) -> Single<HtmlString> {
        let offset = playerRepository.getUtcOffset()
        return offset.flatMap { [unowned self] (offset) -> Single<String> in
            return self.transactionLogRepository.getCasinoWagerDetail(wagerId: wagerId, zoneOffset: offset)
        }
    }
    
    func getSportsBookWagerDetail(wagerId: String) -> Single<HtmlString> {
        let offset = playerRepository.getUtcOffset()
        return offset.flatMap({ [unowned self] (offset) -> Single<String> in
            return self.transactionLogRepository.getSportsBookWagerDetail(wagerId: wagerId, zoneOffset: offset)
        })
    }
}
