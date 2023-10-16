import Foundation
import RxSwift
import sharedbu

protocol NumberGameRecordUseCase {
  func getLatestRecords() -> Observable<[NumberGameSummary.RecentlyBet]>
  func getBetsDetails(wagerId: String) -> Single<NumberGameBetDetail>
  func getSettledSummaries() -> Observable<[NumberGameSummary.Date]>
  func getUnSettledSummaries() -> Observable<[NumberGameSummary.Date]>
  func getGamesSummaryByDate(date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int)
    -> Single<[NumberGameSummary.Game]>
  func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int)
    -> Single<[NumberGameSummary.Bet]>
  func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus)
    -> Single<[NumberGameSummary.Bet]>
}

class NumberGameRecordUseCaseImpl: NumberGameRecordUseCase {
  var numberGameRecordRepository: NumberGameRecordRepository!

  private lazy var recordSummary = numberGameRecordRepository.getBetRecordSummary().asObservable().share(replay: 1)

  init(numberGameRecordRepository: NumberGameRecordRepository) {
    self.numberGameRecordRepository = numberGameRecordRepository
  }

  func getLatestRecords() -> Observable<[NumberGameSummary.RecentlyBet]> {
    recordSummary.map { $0?.latest ?? [] }
  }

  func getBetsDetails(wagerId: String) -> Single<NumberGameBetDetail> {
    numberGameRecordRepository.getBetsDetails(betId: wagerId)
  }

  func getSettledSummaries() -> Observable<[NumberGameSummary.Date]> {
    recordSummary.map { $0?.settled ?? [] }
  }

  func getUnSettledSummaries() -> Observable<[NumberGameSummary.Date]> {
    recordSummary.map { $0?.unsettled ?? [] }
  }

  func getGamesSummaryByDate(
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus,
    skip: Int,
    take: Int) -> Single<[NumberGameSummary.Game]>
  {
    numberGameRecordRepository.getGamesSummaryByDate(date: date, betStatus: betStatus, skip: skip, take: take)
  }

  func getGameBetsByDate(
    gameId: Int32,
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus,
    skip: Int,
    take: Int) -> Single<[NumberGameSummary.Bet]>
  {
    numberGameRecordRepository.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus, skip: skip, take: take)
  }

  func getGameBetsByDate(
    gameId: Int32,
    date: Date,
    betStatus: NumberGameSummary.CompanionStatus) -> Single<[NumberGameSummary.Bet]>
  {
    numberGameRecordRepository.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus)
  }
}
