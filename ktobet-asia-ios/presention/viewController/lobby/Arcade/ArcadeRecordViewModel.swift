import Foundation
import RxSwift
import SharedBu

class ArcadeRecordViewModel {
  private var arcadeRecordUseCase: ArcadeRecordUseCase!

  var recordByDatePagination: Pagination<GameGroupedRecord>!
  var recordDetailPagination: Pagination<ArcadeGameBetRecord>!
  var selectedLocalDate = ""
  var selectedRecord: GameGroupedRecord?

  init(arcadeRecordUseCase: ArcadeRecordUseCase) {
    self.arcadeRecordUseCase = arcadeRecordUseCase

    recordByDatePagination = Pagination<GameGroupedRecord>(
      pageIndex: 0,
      offset: 20,
      observable: { page -> Observable<[GameGroupedRecord]> in
        self.betSummaryByDate(skip: page)
          .do(onError: { error in
            self.recordByDatePagination.error.onNext(error)
          }).catchError({ _ -> Observable<[GameGroupedRecord]> in
            Observable.empty()
          })
      })

    recordDetailPagination = Pagination<ArcadeGameBetRecord>(
      pageIndex: 0,
      offset: 20,
      observable: { page -> Observable<[ArcadeGameBetRecord]> in
        self.getBetDetail(skip: page)
          .do(onError: { error in
            self.recordDetailPagination.error.onNext(error)
          }).catchError({ _ -> Observable<[ArcadeGameBetRecord]> in
            Observable.empty()
          })
      })
  }

  func getBetSummary() -> Single<[DateSummary]> {
    arcadeRecordUseCase.getBetSummary()
  }

  func betSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
    arcadeRecordUseCase.getBetSummaryByDate(localDate: localDate, skip: skip, take: take)
  }

  func betSummaryByDate(skip: Int) -> Observable<[GameGroupedRecord]> {
    arcadeRecordUseCase.getBetSummaryByDate(localDate: selectedLocalDate, skip: skip, take: 20).asObservable()
  }

  func getBetDetail(skip: Int) -> Observable<[ArcadeGameBetRecord]> {
    guard let record = self.selectedRecord else { return Observable.just([]) }
    return arcadeRecordUseCase.getBetRecord(
      startDate: record.startDate,
      endDate: record.endDate,
      gameId: record.gameId,
      skip: skip,
      take: 20).asObservable()
  }
}
