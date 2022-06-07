import Foundation
import RxSwift
import SharedBu

protocol CasinoRecordRepository {
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<BetSummary>
    func getUnsettledSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[UnsettledBetSummary]>
    func getUnsettledRecords(date: SharedBu.LocalDateTime) -> Single<[UnsettledBetRecord]>
    func getPeriodRecords(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[PeriodOfRecord]>
    func getBetRecords(periodOfRecord: PeriodOfRecord, offset: Int) -> Single<[BetRecord]>
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?>
}

class CasinoRecordRepositoryImpl: CasinoRecordRepository {
    private var casinoApi: CasinoApi!
    private var playerConfiguation: PlayerConfiguration!
    
    init(_ casinoApi: CasinoApi, playerConfiguation: PlayerConfiguration) {
        self.casinoApi = casinoApi
        self.playerConfiguation = playerConfiguation
    }
    
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<BetSummary> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getCasinoBetSummary(offset: secondsToHours).map { (response) -> BetSummary in
            guard let d = response.data else { return BetSummary.init(unFinishedGames: 0, finishedGame: []) }
            let finishedGame = d.summaries.map { (s) -> DateSummary in
                return DateSummary(totalStakes: s.stakes.toAccountCurrency(),
                                   totalWinLoss: s.winLoss.toAccountCurrency(),
                                   createdDateTime: s.betDate.toLocalDate(),
                                   count: s.count)
            }
            
            return BetSummary(unFinishedGames: d.pendingTransactionCount, finishedGame: finishedGame)
        }
    }
    
    func getUnsettledSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[UnsettledBetSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getUnsettledSummary(offset: secondsToHours).map { (response) -> [UnsettledBetSummary] in
            guard let data = response.data else { return [] }
            var unsettledBetSummaries: [UnsettledBetSummary] = []
            for s in data {
                let betTime = s.betTime.toLocalDateTime()
                let unsettledBetSummary = UnsettledBetSummary(betTime: betTime)
                unsettledBetSummaries.append(unsettledBetSummary)
            }
            
            return unsettledBetSummaries
        }
    }
    
    func getUnsettledRecords(date: SharedBu.LocalDateTime) -> Single<[UnsettledBetRecord]> {
        return casinoApi.getUnsettledRecords(date: date.toQueryFormatString(timeZone: playerConfiguation.timezone())).map { (response) -> [UnsettledBetRecord] in
            guard let data = response.data else { return [] }
            var unsettledBetRecords: [UnsettledBetRecord] = []
            for d in data {
                let betTime = d.betTime.toLocalDateTime()
                unsettledBetRecords.append(UnsettledBetRecord(betId: d.betId, otherId: d.otherId, gameId: d.gameId, gameName: d.gameName, betTime: betTime, stakes: d.stakes.toAccountCurrency(), prededuct: d.prededuct.toAccountCurrency()))
            }
            
            return unsettledBetRecords
        }
    }
    
    func getPeriodRecords(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[PeriodOfRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getGameGroup(date: localDate, offset: secondsToHours).map { (response) -> [PeriodOfRecord] in
            guard let data = response.data else { return [] }
            var periodOfRecords: [PeriodOfRecord] = []
            for p in data {
                periodOfRecords.append(PeriodOfRecord(endDate: p.endDate.toLocalDateTime(), startDate: p.startDate.toLocalDateTime(), lobbyId: p.lobbyId, lobbyName: p.lobbyName, records: []))
            }
            
            return periodOfRecords
        }
    }
    
    func getBetRecords(periodOfRecord: PeriodOfRecord, offset: Int) -> Single<[BetRecord]> {
        casinoApi.getBetRecordsByPage(lobbyId: Int(periodOfRecord.lobbyId),
                                      beginDate: periodOfRecord.startDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                      endDate: periodOfRecord.endDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                      offset: offset, take: 20).map { (response) -> [BetRecord] in
            guard let data = response.data?.data else { return [] }
            var betRecords: [BetRecord] = []
            for b in data {
                betRecords.append(BetRecord(betId: b.betId, gameName: b.gameName, isEvent: b.showWinLoss, prededuct: b.prededuct.toAccountCurrency(), stakes: b.stakes.toAccountCurrency(), wagerId: b.wagerId, winLoss: b.winLoss.toAccountCurrency(), hasDetails: b.hasDetails))
            }

            return betRecords
        }
    }
    
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
        return casinoApi.getWagerDetail(wagerId: wagerId).map { (response) -> CasinoDetail? in
            guard let data = response.data else { return nil }
            let betTime = data.betTime.toLocalDateTime()
            let casinoBetType = CasinoBetType.Companion.init().convert(type: data.gameType)
            let provider = GameProvider.Companion.init().convert(type: data.gameProviderId)
            let gameResult = CasinoGameResult.Companion.init().create(casinoBetType: casinoBetType, provider: provider, gameResult: data.gameResult)
            return CasinoDetail(betId: data.betId, otherId: data.otherId, betTime: betTime, selection: data.selection, roundId: data.roundId, gameName: data.gameName, gameResult: gameResult, stakes: data.stakes.toAccountCurrency(), prededuct: data.prededuct.toAccountCurrency(), winLoss: data.winLoss.toAccountCurrency(), status: CasinoWagerStatus.Companion.init().convert(type: data.status))
        }
    }
}

