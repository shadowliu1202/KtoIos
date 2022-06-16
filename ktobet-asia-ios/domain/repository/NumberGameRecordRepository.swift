import Foundation
import RxSwift
import SharedBu


protocol NumberGameRecordRepository {
    func getBetRecordSummary() -> Single<(latest: [NumberGameSummary.RecentlyBet], settled: [NumberGameSummary.Date], unsettled: [NumberGameSummary.Date])?>
    func getGamesSummaryByDate(date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Game]>
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Bet]>
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus) -> Single<[NumberGameSummary.Bet]>
    func getBetsDetails(betId: String) -> Single<NumberGameBetDetail>
}

class NumberGameRecordRepositoryImpl: NumberGameRecordRepository {
    private var numberGameApi: NumberGameApi!
    
    init(_ numberGameApi: NumberGameApi) {
        self.numberGameApi = numberGameApi
    }
    
    func getGamesSummaryByDate(date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Game]> {       
        return numberGameApi.getMyBetGameGroupByDate(date: date.toDateString(with: "-"), myBetType:  betStatus.ordinal, skip: skip, take: take).map { (response) -> [NumberGameSummary.Game] in
            guard let data = response.data else { return [] }
            if betStatus == NumberGameSummary.CompanionStatus.settled {
                return data.data.map { $0.toSettleGameSummary(portalHost: KtoURL.baseUrl.absoluteString) }
            } else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
                return data.data.map { $0.toUnSettleGameSummary(portalHost: KtoURL.baseUrl.absoluteString) }
            } else {
                return []
            }
        }
    }
    
    func getBetRecordSummary() -> Single<(latest: [NumberGameSummary.RecentlyBet], settled: [NumberGameSummary.Date], unsettled: [NumberGameSummary.Date])?> {
        return self.numberGameApi.getMyBetSummary().map { (response) -> (latest: [NumberGameSummary.RecentlyBet], settled: [NumberGameSummary.Date], unsettled: [NumberGameSummary.Date])? in
            guard let data = response.data else { return nil }
            
            let settled = try data.settledSummary.details.map { (settledRecords) -> NumberGameSummary.Date in
                return try settledRecords.toNumberGame()
            }
            
            let unSettled = try data.unsettledSummary.details.map { (unsettledRecords) -> NumberGameSummary.Date in
                return try unsettledRecords.toUnSettleNumberGame()
            }
            
            let recently = data.recentlyBets.map { (recentlyBets) -> NumberGameSummary.RecentlyBet in
                return recentlyBets.toNumberGameRecentlyBet()
            }
            
            return (recently, settled, unSettled)
        }
    }
    
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Bet]> {
        let begindate = date.toDateString(with: "/")
        let endDate = date.toDateString(with: "/")
        return numberGameApi.getMyGameBetInDuration(begindate: begindate, endDate: endDate, gameId: gameId, myBetType: betStatus.ordinal, skip: skip).map { (response) -> [NumberGameSummary.Bet] in
            guard let data = response.data else { return [] }
            if betStatus == NumberGameSummary.CompanionStatus.settled {
                return try data.data.map { try $0.toSettleGameSummary() }
            } else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
                return try data.data.map { try $0.toUnSettleGameSummary() }
            } else {
                return []
            }
        }
    }
    
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus) -> Single<[NumberGameSummary.Bet]> {
        let begindate = date.toDateString(with: "/")
        let endDate = date.toDateString(with: "/")
        return numberGameApi.getMyGameBetInDuration(begindate: begindate, endDate: endDate, gameId: gameId, myBetType: betStatus.ordinal).map { (response) -> [NumberGameSummary.Bet] in
            guard let data = response.data else { return [] }
            if betStatus == NumberGameSummary.CompanionStatus.settled {
                return try data.map { try $0.toSettleGameSummary() }
            } else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
                return try data.map { try $0.toUnSettleGameSummary() }
            } else {
                return []
            }
        }
    }
    
    func getBetsDetails(betId: String) -> Single<NumberGameBetDetail> {
        return numberGameApi.getMyBetDetail(wagerId: betId).map { (response) -> NumberGameBetDetail in
            return try response.data.toNumberGameBetDetail()
        }
    }
}
