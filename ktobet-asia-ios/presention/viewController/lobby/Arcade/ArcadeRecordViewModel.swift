import Foundation
import RxSwift
import SharedBu

class ArcadeRecordViewModel {
    private var arcadeRecordUseCase: ArcadeRecordUseCase!
    
    var recordByDatePagination: Pagination<GameGroupedRecord>!
    var recordDetailPagination: Pagination<ArcadeGameBetRecord>!
    var selectedLocalDate: String = ""
    var selectedRecord: GameGroupedRecord?
    
    init(arcadeRecordUseCase: ArcadeRecordUseCase) {
        self.arcadeRecordUseCase = arcadeRecordUseCase
        
        recordByDatePagination = Pagination<GameGroupedRecord>(pageIndex: 0, offset: 20, callBack: {(page) -> Observable<[GameGroupedRecord]> in
            self.betSummaryByDate(skip: page)
                .do(onError: { error in
                    self.recordByDatePagination.error.onNext(error)
                }).catchError( { error -> Observable<[GameGroupedRecord]> in
                    Observable.empty()
                })
        })
        
        recordDetailPagination = Pagination<ArcadeGameBetRecord>(pageIndex: 0, offset: 20, callBack: {(page) -> Observable<[ArcadeGameBetRecord]> in
            self.getBetDetail(skip: page)
                .do(onError: { error in
                    self.recordDetailPagination.error.onNext(error)
                }).catchError( { error -> Observable<[ArcadeGameBetRecord]> in
                    Observable.empty()
                })
        })
    }
    
    func getBetSummary() -> Single<[DateSummary]> {
        arcadeRecordUseCase.getBetSummary()
    }
    
    func betSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
        arcadeRecordUseCase.getBetSummaryByDate(localDate: localDate, skip: skip, take:  take)
    }
    
    func betSummaryByDate(skip: Int) -> Observable<[GameGroupedRecord]> {
        arcadeRecordUseCase.getBetSummaryByDate(localDate: selectedLocalDate, skip: skip, take: 20).asObservable()
    }
    
    func getBetDetail(startDate: String, endDate: String, gameId: Int32, skip: Int, take: Int) -> Single<[ArcadeGameBetRecord]> {
        arcadeRecordUseCase.getBetRecord(startDate: startDate, endDate: endDate, gameId: gameId, skip: skip, take: take)
    }
    
    func getBetDetail(skip: Int) -> Observable<[ArcadeGameBetRecord]> {
        guard let record = self.selectedRecord else { return Observable.just([]) }
        return arcadeRecordUseCase.getBetRecord(startDate: record.startDate.description(), endDate: record.endDate.description(), gameId: record.gameId, skip: skip, take: 20).asObservable()
    }
}
