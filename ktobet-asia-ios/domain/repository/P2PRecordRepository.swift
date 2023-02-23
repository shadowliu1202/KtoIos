import Foundation
import RxSwift
import SharedBu

protocol P2PRecordRepository {
  func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]>
  func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[GameGroupedRecord]>
  func getBetSummaryByGame(beginDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32)
    -> Single<[P2PGameBetRecord]>
}

class P2PRecordRepositoryImpl: P2PRecordRepository {
  private var p2pApi: P2PApi!
  private var localStorageRepo: LocalStorageRepository!
  private var httpClient: HttpClient!

  init(_ p2pApi: P2PApi, localStorageRepo: LocalStorageRepository, httpClient: HttpClient) {
    self.p2pApi = p2pApi
    self.localStorageRepo = localStorageRepo
    self.httpClient = httpClient
  }

  func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]> {
    let secondsToHours = zoneOffset.totalSeconds / 3600

    return p2pApi
      .getBetSummary(offset: secondsToHours)
      .map({ response -> [DateSummary] in
        guard let data = response.data else { return [] }
        return try data.summaries.map({ try $0.toDateSummary() })
      })
  }

  func getBetSummaryByDate(
    localDate: String,
    zoneOffset: SharedBu.UtcOffset) -> Single<[GameGroupedRecord]>
  {
    let secondsToHours = zoneOffset.totalSeconds / 3600

    return p2pApi
      .getGameRecordByDate(
        date: localDate,
        offset: secondsToHours)
      .map({ [unowned self] response -> [GameGroupedRecord] in
        guard let data = response.data else { return [] }

        let groupedDicts = Dictionary(grouping: data, by: { element in
          element.gameGroupId
        })

        let groupedArray = groupedDicts
          .map { (gameGroupId: Int32, value: [P2PDateBetRecordBean]) -> P2PDateBetRecordBean in
            P2PDateBetRecordBean(gameGroupId: gameGroupId, gameList: value)
          }
          .sorted(by: { $0.endDate > $1.endDate })

        let records: [GameGroupedRecord] = try groupedArray
          .map({ try $0.toGameGroupedRecord(host: self.httpClient.host.absoluteString) })

        return records
      })
  }

  func getBetSummaryByGame(
    beginDate: SharedBu.LocalDateTime,
    endDate: SharedBu.LocalDateTime,
    gameId: Int32) -> Single<[P2PGameBetRecord]>
  {
    p2pApi
      .getBetRecords(
        beginDate: beginDate.toQueryFormatString(timeZone: localStorageRepo.timezone()),
        endDate: endDate.toQueryFormatString(timeZone: localStorageRepo.timezone()),
        gameId: gameId)
      .map { response -> [P2PGameBetRecord] in
        guard let data = response.data else { return [] }
        return try data.map({ try $0.toP2PGameBetRecord() })
      }
  }
}
