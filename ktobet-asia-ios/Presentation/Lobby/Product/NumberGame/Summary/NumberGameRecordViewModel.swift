import Foundation
import RxSwift
import sharedbu

class NumberGameRecordViewModel {
    private var numberGameRecordUseCase: NumberGameRecordUseCase!

    lazy var recent = numberGameRecordUseCase.getLatestRecords()
    lazy var settled = numberGameRecordUseCase.getSettledSummaries()
    lazy var unSettled = numberGameRecordUseCase.getUnSettledSummaries()

    var pagination: Pagination<NumberGameSummary.Game>!
    var betPagination: Pagination<NumberGameSummary.Bet>!
    var selectedDate: sharedbu.LocalDate?
    var selectedStatus: NumberGameSummary.CompanionStatus?

    init(numberGameRecordUseCase: NumberGameRecordUseCase) {
        self.numberGameRecordUseCase = numberGameRecordUseCase

        pagination = Pagination<NumberGameSummary.Game>(
            startIndex: 0,
            offset: 20,
            observable: { currentIndex -> Observable<[NumberGameSummary.Game]> in
                self.getGamesSummaryByDate(skip: currentIndex)
                    .do(onError: { error in
                        self.pagination.error.onNext(error)
                    }).catch({ _ -> Observable<[NumberGameSummary.Game]> in
                        Observable.empty()
                    })
            })

        betPagination = Pagination<NumberGameSummary.Bet>(
            startIndex: 0,
            offset: 20,
            observable: { currentIndex -> Observable<[NumberGameSummary.Bet]> in
                self.getGameBetsByDate(skip: currentIndex)
                    .do(onError: { error in
                        self.betPagination.error.onNext(error)
                    }).catch({ _ -> Observable<[NumberGameSummary.Bet]> in
                        Observable.empty()
                    })
            })
    }

    func getGamesSummaryByDate(
        date: Date,
        betStatus: NumberGameSummary.CompanionStatus,
        skip: Int,
        take: Int)
        -> Single<[NumberGameSummary.Game]>
    {
        numberGameRecordUseCase.getGamesSummaryByDate(date: date, betStatus: betStatus, skip: skip, take: take)
    }

    func getUnSettledByDate(date: Date, skip: Int) -> Observable<[NumberGameSummary.Game]> {
        numberGameRecordUseCase.getGamesSummaryByDate(
            date: date,
            betStatus: NumberGameSummary.CompanionStatus.unSettled,
            skip: skip,
            take: 20).asObservable()
    }

    func getGamesSummaryByDate(skip: Int) -> Observable<[NumberGameSummary.Game]> {
        guard let status = selectedStatus, let date = selectedDate?.convertToDate() else { return Observable.empty() }
        return numberGameRecordUseCase.getGamesSummaryByDate(date: date, betStatus: status, skip: skip, take: 20).asObservable()
    }

    var selectedGameId: Int32?
    var selectedBetDate: sharedbu.LocalDate?
    var selectedBetStatus: NumberGameSummary.CompanionStatus?
    func getGameBetsByDate(
        gameId: Int32,
        date: Date,
        betStatus: NumberGameSummary.CompanionStatus,
        skip: Int,
        take: Int)
        -> Single<[NumberGameSummary.Bet]>
    {
        numberGameRecordUseCase.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus, skip: skip, take: take)
    }

    func getGameBetsByDate(
        gameId: Int32,
        date: Date,
        betStatus: NumberGameSummary.CompanionStatus)
        -> Single<[NumberGameSummary.Bet]>
    {
        numberGameRecordUseCase.getGameBetsByDate(gameId: gameId, date: date, betStatus: betStatus)
    }

    func getGameBetsByDate(skip: Int) -> Observable<[NumberGameSummary.Bet]> {
        guard
            let status = selectedBetStatus, let date = selectedBetDate?.convertToDate(),
            let gameId = selectedGameId else { return Observable.empty() }
        return getGameBetsByDate(gameId: gameId, date: date, betStatus: status, skip: skip, take: 100).asObservable()
    }

    func getRecentGamesDetail(wagerIds: [String]) -> Single<[NumberGameBetDetail]> {
        Single.zip(wagerIds.map({ [weak self] id -> Single<NumberGameBetDetail> in
            guard let self else { return Single.never() }
            return self.numberGameRecordUseCase.getBetsDetails(wagerId: id)
        }))
    }

    func getGameDetail(wagerId: String) -> Single<NumberGameBetDetail> {
        self.numberGameRecordUseCase.getBetsDetails(wagerId: wagerId)
    }
}
