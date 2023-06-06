import Foundation
import RxCocoa
import RxSwift
import SharedBu

enum DeleteMode {
  case include
  case exclude
}

class CustomerServiceHistoryViewModel {
  private var historyUseCase: ChatRoomHistoryUseCase!
  private var disposeBag = DisposeBag()
  private var historiesTotalCount = 0 {
    didSet {
      chatHistoryTotalSize.accept(historiesTotalCount)
    }
  }

  private lazy var chatHistories = BehaviorSubject<[ChatHistory]?>(value: nil)
  private var chatHistoryTotalSize = BehaviorRelay<Int>(value: 0)
  private(set) var deleteMode = BehaviorRelay<DeleteMode>(value: .include)
  lazy var selectedHistory = BehaviorRelay<[ChatHistory]>(value: [])

  init(historyUseCase: ChatRoomHistoryUseCase) {
    self.historyUseCase = historyUseCase
  }

  func hasNext(_ lastIndex: Int) -> Bool {
    lastIndex < historiesTotalCount - 1
  }

  func refreshData() {
    fetchNext(from: 0)
  }

  func getChatHistories() -> Observable<[ChatHistory]> {
    chatHistories.compactMap({ $0 })
  }

  func fetchNext(from lastIndex: Int) {
    let page = ((lastIndex + 1) / 20) + 1
    self.getchatHistory(page).subscribe(onSuccess: { [weak self] response in
      self?.historiesTotalCount = response.0
      if var copyValue = try? self?.chatHistories.value() {
        let data = response.1
        if lastIndex == 0 {
          copyValue.removeAll()
        }
        copyValue.append(contentsOf: data)
        self?.chatHistories.onNext(copyValue)
      }
      else {
        let data = response.1
        self?.chatHistories.onNext(data)
      }
    }, onFailure: { [weak self] error in
      self?.chatHistories.onError(error)
    }).disposed(by: disposeBag)
  }

  private func getchatHistory(_ page: Int) -> Single<(TotalCount, [ChatHistory])> {
    historyUseCase.getChatHistorySummaries(page: page)
  }

  func updateDeleteMode(_ mode: DeleteMode) {
    deleteMode.accept(mode)
    selectedHistory.accept([])
  }

  func updateSelection(_ history: ChatHistory) {
    var copyValue = selectedHistory.value
    if let i = copyValue.firstIndex(of: history) {
      copyValue.remove(at: i)
    }
    else {
      copyValue.append(history)
    }
    selectedHistory.accept(copyValue)
  }

  lazy var deleteCount = Observable.combineLatest(deleteMode, chatHistoryTotalSize, selectedHistory)
    .map({ mode, totalSize, selection -> Int in
      switch mode {
      case .include:
        return selection.count
      case .exclude:
        return totalSize - selection.count
      }
    })

  lazy var isDeleteValid = Observable.combineLatest(deleteMode, chatHistoryTotalSize, selectedHistory)
    .map({ mode, totalSize, selection -> Bool in
      switch mode {
      case .include:
        return !selection.isEmpty
      case .exclude:
        return totalSize != selection.count
      }
    })

  lazy var isAllHistorySelected = Observable.combineLatest(deleteMode, chatHistoryTotalSize, selectedHistory)
    .map({ mode, totalSize, selection -> Bool in
      switch mode {
      case .include:
        return totalSize == selection.count
      case .exclude:
        return selection.isEmpty
      }
    })

  func deleteChatHistory() -> Completable {
    historyUseCase.deleteChatHistories(chatHistories: selectedHistory.value, isExclude: deleteMode.value == .exclude)
  }

  func getChatHistory(roomId: String) -> Observable<[ChatMessage]> {
    historyUseCase.getChatHistories(roomId: roomId).asObservable()
  }
}
