import Foundation
import RxCocoa
import RxSwift
import sharedbu

class SlotBetViewModel: CollectErrorViewModel, ProductWebGameViewModelProtocol {
  @Injected private var loading: Loading

  let PaginationTake = 20
  private var slotUseCase: SlotUseCase!
  private var slotRecordUseCase: SlotRecordUseCase!
  lazy var betSummary = PublishSubject<BetSummary>()
  lazy var betRecordDetails = BehaviorSubject<[SlotBetRecord]>(value: [])
  private var betRecordDetailsTotalCount: Int32 = 0
  lazy var unsettledBetSummary = BehaviorSubject<[SlotUnsettledSection]>(value: [])
  private var disposeBag = DisposeBag()

  var loadingWebTracker: ActivityIndicator { loading.tracker }

  private let webGameResultSubject = PublishSubject<WebGameResult>()
  var webGameResultDriver: Driver<WebGameResult> {
    webGameResultSubject.asDriverLogError()
  }

  init(slotUseCase: SlotUseCase, slotRecordUseCase: SlotRecordUseCase) {
    self.slotUseCase = slotUseCase
    self.slotRecordUseCase = slotRecordUseCase
  }

  func fetchBetSummary() {
    slotRecordUseCase.getBetSummary().subscribe(onSuccess: { [weak self] summaries in
      if summaries.unFinishedGames == 0, summaries.finishedGame.count == 0 {
        self?.betSummary.onError(KTOError.EmptyData)
      }
      else {
        self?.betSummary.onNext(summaries)
      }
    }, onFailure: { [weak self] error in
      self?.betSummary.onError(error)
    }).disposed(by: disposeBag)
  }

  func betSummaryByDate(localDate: String) -> Single<[SlotGroupedRecord]> {
    slotRecordUseCase.getSlotGameRecordByDate(localDate: localDate)
  }

  func hasNextRecord(_ lastIndex: Int) -> Bool {
    lastIndex < betRecordDetailsTotalCount - 1
  }

  func fetchNextBetRecords(recordData: SlotGroupedRecord, _ lastIndex: Int) {
    let offset = lastIndex == 0 ? 0 : lastIndex + 1
    self
      .getBetRecords(offset: offset, startDate: recordData.startDate, endDate: recordData.endDate, gameId: recordData.gameId)
      .subscribe(
        onSuccess: { [weak self] response in
          if response.data is [SlotBetRecord], var copyValue = try? self?.betRecordDetails.value() {
            self?.betRecordDetailsTotalCount = response.totalCount
            let data = response.data as! [SlotBetRecord]
            copyValue.append(contentsOf: data)
            self?.betRecordDetails.onNext(copyValue)
          }
        },
        onFailure: { [weak self] error in
          self?.betRecordDetails.onError(error)
        }).disposed(by: disposeBag)
  }

  private func getBetRecords(
    offset: Int,
    startDate: sharedbu.LocalDateTime,
    endDate: sharedbu.LocalDateTime,
    gameId: Int32) -> Single<CommonPage<SlotBetRecord>>
  {
    slotRecordUseCase.getBetRecordByPage(
      startDate: startDate,
      endDate: endDate,
      gameId: gameId,
      offset: offset,
      take: PaginationTake)
  }

  func fetchUnsettledBetSummary() {
    slotRecordUseCase.getUnsettledSummary()
      .subscribe(onSuccess: { [weak self] summaries in
        if summaries.count > 0 {
          let section = summaries.map({ SlotUnsettledSection($0) })
          if let originValue = try? self?.unsettledBetSummary.value() {
            section.forEach({ element in
              element.expanded = originValue.first(where: { $0.betTime == element.betTime })?.expanded ?? false
              if element.expanded {
                _ = self?.getRecordOfExpandedSection(element)
              }
            })
          }
          self?.unsettledBetSummary.onNext(section)
        }
        else {
          self?.unsettledBetSummary.onError(KTOError.EmptyData)
        }
      }, onFailure: { [weak self] error in
        self?.unsettledBetSummary.onError(error)
      }).disposed(by: disposeBag)
  }

  private func getRecordOfExpandedSection(_ section: SlotUnsettledSection) {
    fetchNextUnsettledRecords(betTime: section.betTime, 0).subscribe().disposed(by: disposeBag)
  }

  func fetchNextUnsettledRecords(betTime: sharedbu.LocalDateTime, _ lastIndex: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
    let offset = lastIndex == 0 ? 0 : lastIndex + 1
    return self.getUnsettledRecords(betTime: betTime, offset: offset).do(onSuccess: { [weak self] response in
      guard
        let self,
        let sections = try? self.unsettledBetSummary.value(),
        let currentSection = sections.filter({ $0.betTime == betTime }).first else { return }
      currentSection.totalCount = response.totalCount
      if response.data is [SlotUnsettledRecord] {
        let records = response.data.map({ $0 as! SlotUnsettledRecord })
        if offset == 0 { currentSection.records.removeAll() }
        currentSection.uniqueAppend(records)
        self.unsettledBetSummary.onNext(sections)
      }
    })
  }

  private func getUnsettledRecords(betTime: sharedbu.LocalDateTime, offset: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
    slotRecordUseCase.getUnsettledRecords(betTime: betTime, offset: offset, take: PaginationTake)
  }
}

extension SlotBetViewModel {
  func getGameProduct() -> String { "slot" }

  func getGameProductType() -> ProductType {
    ProductType.slot
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    slotUseCase.checkBonusAndCreateGame(game)
  }

  func fetchGame(_ game: WebGame) {
    configFetchGame(
      game,
      resultSubject: webGameResultSubject,
      errorSubject: errorsSubject)
      .disposed(by: disposeBag)
  }
}

class SlotUnsettledSection {
  private let summary: SlotUnsettledSummary
  var records: [SlotUnsettledRecord] = []

  var betTime: sharedbu.LocalDateTime {
    summary.betTime
  }

  var totalCount: Int32 = 0
  var expanded = false

  init(_ bean: SlotUnsettledSummary) {
    self.summary = bean
  }

  func uniqueAppend(_ elements: [SlotUnsettledRecord]) {
    let filteredList = elements.filter({ !self.records.contains($0) })
    self.records.append(contentsOf: filteredList)
  }

  func hasNextRecord(_ lastIndex: Int) -> Bool {
    lastIndex < totalCount - 1
  }
}
