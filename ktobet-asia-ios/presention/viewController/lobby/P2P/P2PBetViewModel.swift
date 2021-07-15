import Foundation
import RxSwift
import SharedBu

class P2PBetViewModel {
    private var p2pRecordUseCase: P2PRecordUseCase!
    
    var betSummary = PublishSubject<MyBetSummary>()
    
    private var disposeBag = DisposeBag()
    
    init(p2pRecordUseCase: P2PRecordUseCase) {
        self.p2pRecordUseCase = p2pRecordUseCase
    }
    
    func getBetSummary() -> Single<[DateSummary]> {
        return p2pRecordUseCase.getBetSummary()
    }
    
    func fetchBetSummary() {
        self.getBetSummary().subscribe(onSuccess: { [weak self] (summaries) in
            if summaries.count == 0 {
                self?.betSummary.onError(KTOError.EmptyData)
            } else {
                self?.betSummary.onNext(SummaryAdapter(summaries))
            }
        }, onError: { [weak self] (error) in
            self?.betSummary.onError(error)
        }).disposed(by: disposeBag)
    }
    
    func betSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]> {
        return p2pRecordUseCase.getBetSummaryByDate(localDate: localDate)
    }
    
    func getBetDetail(startDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecord]> {
        return p2pRecordUseCase.getBetRecord(startDate: startDate, endDate: endDate, gameId: gameId)
    }
}
