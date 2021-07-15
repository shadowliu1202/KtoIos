import Foundation
import SharedBu
import RxSwift

protocol P2PRecordUseCase {
    func getBetSummary() -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]>
    func getBetRecord(startDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecord]>
}

class P2PRecordUseCaseImpl: P2PRecordUseCase {
    
    var p2pRecordRepository : P2PRecordRepository!
    var playerRepository : PlayerRepository!
    
    init(_ p2pRecordRepository : P2PRecordRepository, _ playerRepository : PlayerRepository) {
        self.p2pRecordRepository = p2pRecordRepository
        self.playerRepository = playerRepository
    }
    
    func getBetSummary() -> Single<[DateSummary]> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap { [unowned self] (offset) -> Single<[DateSummary]> in
            return self.p2pRecordRepository.getBetSummary(zoneOffset: offset)
        }
    }
    
    func getBetSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap { [unowned self] (offset) -> Single<[GameGroupedRecord]> in
            return self.p2pRecordRepository.getBetSummaryByDate(localDate: localDate, zoneOffset: offset)
        }
    }
    
    func getBetRecord(startDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecord]> {
        let zoneOffset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return zoneOffset.flatMap { [unowned self] (zoneOffset) -> Single<[P2PGameBetRecord]> in
            return self.p2pRecordRepository.getBetSummaryByGame(beginDate: startDate, endDate: endDate, gameId: gameId)
        }
    }
    
}
