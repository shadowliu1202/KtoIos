import Foundation
import RxSwift
import RxCocoa
import SharedBu

class SlotBetViewModel {
    let PaginationTake = 20
    private var slotUseCase: SlotUseCase!
    private var slotRecordUseCase : SlotRecordUseCase!
    lazy var betSummary = PublishSubject<BetSummary>()
    lazy var betRecordDetails = BehaviorSubject<[SlotBetRecord]>(value: [])
    private var betRecordDetailsTotalCount: Int32 = 0
    lazy var unsettledBetSummary = BehaviorSubject<[SlotUnsettledSection]>(value: [])
    private var disposeBag = DisposeBag()
    
    init(slotUseCase: SlotUseCase, slotRecordUseCase: SlotRecordUseCase) {
        self.slotUseCase = slotUseCase
        self.slotRecordUseCase = slotRecordUseCase
    }
    
    func fetchBetSummary() {
        slotRecordUseCase.getBetSummary().subscribe(onSuccess: { [weak self] (summaries) in
            if summaries.unFinishedGames == 0 && summaries.finishedGame.count == 0 {
                self?.betSummary.onError(KTOError.EmptyData)
            } else {
                self?.betSummary.onNext(summaries)
            }
        }, onError: { [weak self] (error) in
            self?.betSummary.onError(error)
        }).disposed(by: disposeBag)
    }
    
    func betSummaryByDate(localDate: String) -> Single<[SlotGroupedRecord]> {
        return slotRecordUseCase.getSlotGameRecordByDate(localDate: localDate)
    }
    
    func hasNextRecord(_ lastIndex: Int) -> Bool {
        return lastIndex < betRecordDetailsTotalCount - 1
    }
    
    func fetchNextBetRecords(recordData: SlotGroupedRecord, _ lastIndex: Int) {
        let offset = lastIndex == 0 ? 0 : lastIndex + 1
        let start: String = recordData.startDate.description()
        let end = recordData.endDate.description()
        self.getBetRecords(offset: offset, startDate: start, endDate: end, gameId: recordData.gameId).subscribe(onSuccess: { [weak self] (response) in
            if response.data is [SlotBetRecord], var copyValue = try? self?.betRecordDetails.value() {
                self?.betRecordDetailsTotalCount = response.totalCount
                let data = response.data as! [SlotBetRecord]
                copyValue.append(contentsOf: data)
                self?.betRecordDetails.onNext(copyValue)
            }
        }, onError: { [weak self] (error) in
            self?.betRecordDetails.onError(error)
        }).disposed(by: disposeBag)
    }
    
    private func getBetRecords(offset: Int, startDate: String, endDate: String, gameId: Int32) -> Single<CommonPage<SlotBetRecord>> {
        return slotRecordUseCase.getBetRecordByPage(startDate: startDate, endDate: endDate, gameId: gameId, offset: offset, take: PaginationTake)
    }
    
    func fetchUnsettledBetSummary() {
        slotRecordUseCase.getUnsettledSummary().asObservable().share(replay: 1)
            .subscribe(onNext: { [weak self] (summaries) in
                if summaries.count > 0 {
                    let section = summaries.map({ SlotUnsettledSection($0) })
                    self?.unsettledBetSummary.onNext(section)
                } else {
                    self?.unsettledBetSummary.onError(KTOError.EmptyData)
                }
        }, onError: { [weak self] (error) in
            self?.unsettledBetSummary.onError(error)
        }).disposed(by: disposeBag)
    }
    
    func fetchNextUnsettledRecords(betTime: Kotlinx_datetimeLocalDateTime, _ lastIndex: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
        let offset = lastIndex == 0 ? 0 : lastIndex + 1
        return self.getUnsettledRecords(betTime: betTime, offset: offset).do(onSuccess: { [weak self] (response) in
            guard let `self` = self,
                  let sections = try? self.unsettledBetSummary.value(),
                  let currentSection = sections.filter({ $0.betTime == betTime }).first else { return }
            currentSection.totalCount = response.totalCount
            if response.data is [SlotUnsettledRecord] {
                let records = response.data.map({$0 as! SlotUnsettledRecord})
                currentSection.uniqueAppend(records)
                self.unsettledBetSummary.onNext(sections)
            }
        })
    }
    
    private func getUnsettledRecords(betTime: Kotlinx_datetimeLocalDateTime, offset: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
        return slotRecordUseCase.getUnsettledRecords(betTime: betTime, offset: offset, take: PaginationTake)
    }
}

extension SlotBetViewModel: ProductWebGameViewModelProtocol {
    func getGameProduct() -> String { "slot" }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return slotUseCase.createGame(gameId: gameId)
    }
}

class SlotUnsettledSection {
    private let summary: SlotUnsettledSummary
    private(set) var records: [SlotUnsettledRecord] = []
    
    var betTime: Kotlinx_datetimeLocalDateTime {
        return summary.betTime
    }
    var totalCount: Int32 = 0
    var expanded: Bool = false
    
    init(_ bean: SlotUnsettledSummary) {
        self.summary = bean
    }
    
    func uniqueAppend(_ elements: [SlotUnsettledRecord]) {
        let filteredList = elements.filter({!self.records.contains($0)})
        self.records.append(contentsOf: filteredList)
    }
    
    func hasNextRecord(_ lastIndex: Int) -> Bool {
        return lastIndex < totalCount - 1
    }
}
