import Foundation
import SharedBu
import RxSwift

class NumberGameRecordViewModel {
    private var numberGameRecordUseCase: NumberGameRecordUseCase!
    
    lazy var recent = numberGameRecordUseCase.getLatestRecords()
    lazy var settled = numberGameRecordUseCase.getSettledSummaries()
    lazy var unSettled = numberGameRecordUseCase.getUnSettledSummaries()
    
    var pagination: Pagination<NumberGameSummary.Game>!
    var betPagination: Pagination<NumberGameSummary.Bet>!
    var selectedDate: Kotlinx_datetimeLocalDate?
    var selectedStatus: NumberGameSummary.CompanionStatus?
    
    init(numberGameRecordUseCase: NumberGameRecordUseCase) {
        self.numberGameRecordUseCase = numberGameRecordUseCase
        
        pagination = Pagination<NumberGameSummary.Game>(pageIndex: 0, offset: 20, callBack: {(page) -> Observable<[NumberGameSummary.Game]> in
            self.getGamesSummaryByDate(skip: page)
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError( { error -> Observable<[NumberGameSummary.Game]> in
                    Observable.empty()
                })
        })
        
        betPagination = Pagination<NumberGameSummary.Bet>(pageIndex: 0, offset: 20, callBack: {(page) -> Observable<[NumberGameSummary.Bet]> in
            self.getGameBetsByDate(skip: page)
                .do(onError: { error in
                    self.betPagination.error.onNext(error)
                }).catchError( { error -> Observable<[NumberGameSummary.Bet]> in
                    Observable.empty()
                })
        })
    }
    
    func getGamesSummaryByDate(date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Game]> {
        return numberGameRecordUseCase.getGamesSummaryByDate(date: date, betStatus: betStatus, skip: skip, take: take)
    }
    
    func getUnSettledByDate(date: Date, skip: Int) -> Observable<[NumberGameSummary.Game]> {
        return numberGameRecordUseCase.getGamesSummaryByDate(date: date, betStatus: NumberGameSummary.CompanionStatus.unsettled, skip: skip, take: 20).asObservable()
    }
    
    func getGamesSummaryByDate(skip: Int) -> Observable<[NumberGameSummary.Game]> {
        guard let status = selectedStatus, let date = selectedDate?.convertToDate() else { return Observable.empty() }
        return numberGameRecordUseCase.getGamesSummaryByDate(date: date, betStatus: status, skip: skip, take: 20).asObservable()
    }
    
    var selectedGameId: Int32?
    var selectedBetDate: Kotlinx_datetimeLocalDate?
    var selectedBetStatus: NumberGameSummary.CompanionStatus?
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus, skip: Int, take: Int) -> Single<[NumberGameSummary.Bet]> {
        return numberGameRecordUseCase.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus, skip: skip, take: take)
    }
    
    func getGameBetsByDate(gameId: Int32, date: Date, betStatus: NumberGameSummary.CompanionStatus) -> Single<[NumberGameSummary.Bet]> {
        return numberGameRecordUseCase.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus)
    }
    
    func getGameBetsByDate(skip: Int) -> Observable<[NumberGameSummary.Bet]> {
        guard let status = selectedBetStatus, let date = selectedBetDate?.convertToDate(), let gameId = selectedGameId else { return Observable.empty() }
        return getGameBetsByDate(gameId: gameId, date: date, betStatus: status, skip: skip, take: 100).asObservable()
    }
    
    func getRecentGamesDetail(wagerIds: [String]) -> Single<[NumberGameBetDetail]> {
        return Single.zip(wagerIds.map({ [weak self] (id) -> Single<NumberGameBetDetail> in
            guard let `self` = self else { return Single.never() }
            return self.numberGameRecordUseCase.getBetsDetails(wagerId: id)
        }))
    }
}
