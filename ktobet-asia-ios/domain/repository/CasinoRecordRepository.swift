import Foundation
import RxSwift
import share_bu

protocol CasinoRecordRepository {
    func getBetSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<BetSummary>
    func getUnsettledSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[UnsettledBetSummary]>
    func getUnsettledRecords(date: String) -> Single<[UnsettledBetRecord]>
    func getPeriodRecords(localDate: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[PeriodOfRecord]>
    func getBetRecords(periodOfRecord: PeriodOfRecord) -> Single<[BetRecord]>
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?>
}

class CasinoRecordRepositoryImpl: CasinoRecordRepository {
    private var casinoApi: CasinoApi!
    
    init(_ casinoApi: CasinoApi) {
        self.casinoApi = casinoApi
    }
    
    func getBetSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<BetSummary> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getCasinoBetSummary(offset: secondsToHours).map { (response) -> BetSummary in
            guard let d = response.data else { return BetSummary.init(unFinishedGames: 0, finishedGame: []) }
            let finishedGame = d.summaries.map { (s) -> DateSummary in
                let createDate = s.betDate.convertDateTime(format:  "yyyy/MM/dd") ?? Date()
                return DateSummary(totalStakes: CashAmount(amount: s.stakes),
                                   totalWinLoss: CashAmount(amount: s.winLoss),
                                   createdDateTime: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()),
                                   count: s.count)
            }
            
            return BetSummary(unFinishedGames: d.pendingTransactionCount, finishedGame: finishedGame)
        }
    }
    
    func getUnsettledSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[UnsettledBetSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getUnsettledSummary(offset: secondsToHours).map { (response) -> [UnsettledBetSummary] in
            guard let data = response.data else { return [] }
            var unsettledBetSummaries: [UnsettledBetSummary] = []
            for s in data {
                let betTime = String(s.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: nil) ?? Date()
                let unsettledBetSummary = UnsettledBetSummary(betTime: Kotlinx_datetimeLocalDateTime.init(year: betTime.getYear(), monthNumber: betTime.getMonth(), dayOfMonth: betTime.getDayOfMonth(), hour: betTime.getHour(), minute: betTime.getMinute(), second: betTime.getSecond(), nanosecond: betTime.getNanosecond()))
                unsettledBetSummaries.append(unsettledBetSummary)
            }
            
            return unsettledBetSummaries
        }
    }
    
    func getUnsettledRecords(date: String) -> Single<[UnsettledBetRecord]> {
        return casinoApi.getUnsettledRecords(date: date).map { (response) -> [UnsettledBetRecord] in
            guard let data = response.data else { return [] }
            var unsettledBetRecords: [UnsettledBetRecord] = []
            for d in data {
                let betTime = String(d.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: nil) ?? Date()
                unsettledBetRecords.append(UnsettledBetRecord(betId: d.betId, otherId: d.otherId, gameId: d.gameId, gameName: d.gameName, betTime: Kotlinx_datetimeLocalDateTime.init(year: betTime.getYear(), monthNumber: betTime.getMonth(), dayOfMonth: betTime.getDayOfMonth(), hour: betTime.getHour(), minute: betTime.getMinute(), second: betTime.getSecond(), nanosecond: betTime.getNanosecond()), stakes: CashAmount(amount: d.stakes), prededuct: CashAmount(amount: d.prededuct)))
            }
            
            return unsettledBetRecords
        }
    }
    
    func getPeriodRecords(localDate: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[PeriodOfRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return casinoApi.getGameGroup(date: localDate, offset: secondsToHours).map { (response) -> [PeriodOfRecord] in
            guard let data = response.data else { return [] }
            var periodOfRecords: [PeriodOfRecord] = []
            let format1 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let format2 = "yyyy-MM-dd'T'HH:mm:ssZ"
            for p in data {
                let startDate = p.startDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()
                let endDate = p.endDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()
                periodOfRecords.append(PeriodOfRecord(endDate: endDate.convertToKotlinx_datetimeLocalDateTime(), startDate: startDate.convertToKotlinx_datetimeLocalDateTime(), lobbyId: p.lobbyId, lobbyName: p.lobbyName, records: []))
            }
            
            return periodOfRecords
        }
    }
    
    func getBetRecords(periodOfRecord: PeriodOfRecord) -> Single<[BetRecord]> {
        let starString = "\(periodOfRecord.startDate)"
        let endString = "\(periodOfRecord.endDate)"
        return casinoApi.getBetRecordsByPage(lobbyId: Int(periodOfRecord.lobbyId), beginDate: starString, endDate: endString, offset: 0, take: 20).map { (response) -> [BetRecord] in
            guard let data = response.data?.data else { return [] }
            var betRecords: [BetRecord] = []
            for b in data {
                betRecords.append(BetRecord(betId: b.betId, gameName: b.gameName, isEvent: b.showWinLoss, prededuct: CashAmount(amount: b.prededuct), stakes: CashAmount(amount: b.stakes), wagerId: b.wagerId, winLoss: CashAmount(amount: b.winLoss), hasDetails: b.hasDetails))
            }
            
            return betRecords
        }
    }
    
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
        return casinoApi.getWagerDetail(wagerId: wagerId).map { (response) -> CasinoDetail? in
            guard let data = response.data else { return nil }
            let betTime = String(data.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()
            let casinoBetType = CasinoBetType.Companion.init().convert(type: data.gameType)
            let provider = GameProvider.Companion.init().convert(type: data.gameProviderId)
            let gameResult = CasinoGameResult.Companion.init().create(casinoBetType: casinoBetType, provider: provider, gameResult: data.gameResult)
            return CasinoDetail(betId: data.betId, otherId: data.otherId, betTime: betTime.convertToKotlinx_datetimeLocalDateTime(), selection: data.selection, roundId: data.roundId, gameName: data.gameName, gameResult: gameResult, stakes: CashAmount(amount: data.stakes), prededuct: CashAmount(amount: data.prededuct), winLoss: CashAmount(amount: data.winLoss), status: CasinoWagerStatus.Companion.init().convert(type: data.status))
        }
    }
}

