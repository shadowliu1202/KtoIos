import Foundation
import RxSwift
import SharedBu

class P2PBetViewModel {
    private (set) var betSummary = PublishSubject<MyBetSummary>()
    
    private var p2pRecordUseCase: P2PRecordUseCase!
    
    private var disposeBag = DisposeBag()
    
    init(p2pRecordUseCase: P2PRecordUseCase) {
        self.p2pRecordUseCase = p2pRecordUseCase
    }
    
    func getBetSummary() -> Single<[DateSummary]> {
        p2pRecordUseCase.getBetSummary()
    }
    
    func fetchBetSummary() {
        getBetSummary()
            .subscribe(onSuccess: { [weak self] (summaries) in
                if summaries.count == 0 {
                    self?.betSummary.onError(KTOError.EmptyData)
                }
                else {
                    self?.betSummary.onNext(SummaryAdapter(summaries))
                }
            }, onFailure: { [weak self] (error) in
                self?.betSummary.onError(error)
            })
            .disposed(by: disposeBag)
    }
    
    func betSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]> {
        p2pRecordUseCase.getBetSummaryByDate(localDate: localDate)
    }
    
    func getBetDetail(
        startDate: SharedBu.LocalDateTime,
        endDate: SharedBu.LocalDateTime,
        gameId: Int32
    ) -> Single<[P2PGameBetRecord]> {
        
        p2pRecordUseCase.getBetRecord(
            startDate: startDate,
            endDate: endDate,
            gameId: gameId
        )
    }
}
