import Foundation
import RxSwift
import SharedBu

protocol NumberGameRecordRepository {
  func getBetRecordSummary()
    -> Single<(
      latest: [NumberGameSummary.RecentlyBet],
      settled: [NumberGameSummary.Date],
      unsettled: [NumberGameSummary.Date])?>
  func getGamesSummaryByDate(date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int)
    -> Single<[NumberGameSummary.Game]>
  func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int)
    -> Single<[NumberGameSummary.Bet]>
  func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus)
    -> Single<[NumberGameSummary.Bet]>
  func getBetsDetails(betId: String) -> Single<NumberGameBetDetail>
}

class NumberGameRecordRepositoryImpl: NumberGameRecordRepository {
  private var numberGameApi: NumberGameApi!
  private var httpClient: HttpClient!

  init(_ numberGameApi: NumberGameApi, httpClient: HttpClient) {
    self.numberGameApi = numberGameApi
    self.httpClient = httpClient
  }

  func getGamesSummaryByDate(
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus,
    skip: Int,
    take: Int) -> Single<[NumberGameSummary.Game]>
  {
    numberGameApi.getMyBetGameGroupByDate(
      date: date.toDateString(with: "-"),
      myBetType: betStatus.ordinal,
      skip: skip,
      take: take).map { [unowned self] response -> [NumberGameSummary.Game] in
      guard let data = response.data else { return [] }
      if betStatus == NumberGameSummary.CompanionStatus.settled {
        return data.data.map { $0.toSettleGameSummary(portalHost: self.httpClient.host.absoluteString) }
      }
      else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
        return data.data.map { $0.toUnSettleGameSummary(portalHost: self.httpClient.host.absoluteString) }
      }
      else {
        return []
      }
    }
  }

  func getBetRecordSummary()
    -> Single<(
      latest: [NumberGameSummary.RecentlyBet],
      settled: [NumberGameSummary.Date],
      unsettled: [NumberGameSummary.Date])?>
  {
    self.numberGameApi.getMyBetSummary().map { response -> (
      latest: [NumberGameSummary.RecentlyBet],
      settled: [NumberGameSummary.Date],
      unsettled: [NumberGameSummary.Date])? in
      guard let data = response.data else { return nil }

      let settled = try data.settledSummary.details.map { settledRecords -> NumberGameSummary.Date in
        try settledRecords.toNumberGame()
      }

      let unSettled = try data.unsettledSummary.details.map { unsettledRecords -> NumberGameSummary.Date in
        try unsettledRecords.toUnSettleNumberGame()
      }

      let recently = data.recentlyBets.map { recentlyBets -> NumberGameSummary.RecentlyBet in
        recentlyBets.toNumberGameRecentlyBet()
      }

      return (recently, settled, unSettled)
    }
  }

  func getGameBetsByDate(
    gameId: Int32,
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus,
    skip: Int,
    take _: Int) -> Single<[NumberGameSummary.Bet]>
  {
    let begindate = date.toDateString(with: "/")
    let endDate = date.toDateString(with: "/")
    return numberGameApi.getMyGameBetInDuration(
      begindate: begindate,
      endDate: endDate,
      gameId: gameId,
      myBetType: betStatus.ordinal,
      skip: skip).map { response -> [NumberGameSummary.Bet] in
      guard let data = response.data else { return [] }
      if betStatus == NumberGameSummary.CompanionStatus.settled {
        return try data.data.map { try $0.toSettleGameSummary() }
      }
      else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
        return try data.data.map { try $0.toUnSettleGameSummary() }
      }
      else {
        return []
      }
    }
  }

  func getGameBetsByDate(
    gameId: Int32,
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus) -> Single<[NumberGameSummary.Bet]>
  {
    let begindate = date.toDateString(with: "/")
    let endDate = date.toDateString(with: "/")
    return numberGameApi.getMyGameBetInDuration(
      begindate: begindate,
      endDate: endDate,
      gameId: gameId,
      myBetType: betStatus.ordinal).map { response -> [NumberGameSummary.Bet] in
      guard let data = response.data else { return [] }
      if betStatus == NumberGameSummary.CompanionStatus.settled {
        return try data.map { try $0.toSettleGameSummary() }
      }
      else if betStatus == NumberGameSummary.CompanionStatus.unsettled {
        return try data.map { try $0.toUnSettleGameSummary() }
      }
      else {
        return []
      }
    }
  }

  func getBetsDetails(betId: String) -> Single<NumberGameBetDetail> {
    numberGameApi.getMyBetDetail(wagerId: betId).map { response -> NumberGameBetDetail in
      try response.data.toNumberGameBetDetail()
    }
  }
}
