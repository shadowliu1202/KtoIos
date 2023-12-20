import Foundation
import RxSwift
import sharedbu

protocol P2PRecordRepository {
  func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[DateSummary]>
  func getBetSummaryByDate(localDate: String, zoneOffset: sharedbu.UtcOffset) -> Single<[GameGroupedRecord]>
  func getBetSummaryByGame(beginDate: sharedbu.LocalDateTime, endDate: sharedbu.LocalDateTime, gameId: Int32)
    -> Single<[P2PGameBetRecord]>
}

class P2PRecordRepositoryImpl: P2PRecordRepository {
  private let p2pApi: P2PApi
  private let playerConfiguration: PlayerConfiguration
  private let httpClient: HttpClient

  init(
    _ p2pApi: P2PApi,
    _ playerConfiguration: PlayerConfiguration,
    _ httpClient: HttpClient)
  {
    self.p2pApi = p2pApi
    self.playerConfiguration = playerConfiguration
    self.httpClient = httpClient
  }

  func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[DateSummary]> {
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
    zoneOffset: sharedbu.UtcOffset) -> Single<[GameGroupedRecord]>
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
    beginDate: sharedbu.LocalDateTime,
    endDate: sharedbu.LocalDateTime,
    gameId: Int32) -> Single<[P2PGameBetRecord]>
  {
    p2pApi
      .getBetRecords(
        beginDate: beginDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
        endDate: endDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
        gameId: gameId)
      .map { response -> [P2PGameBetRecord] in
        guard let data = response.data else { return [] }
        return try data.map({ try $0.toP2PGameBetRecord() })
      }
  }
}
