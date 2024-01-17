import Combine
import sharedbu

protocol ChatHistoriesEditViewModelProtocol {
  var histories: [CustomerServiceDTO.ChatHistoriesHistory] { get }
  var selectedHistories: SelectedHistories { get }
  
  func toggleSelectAll()
  func getMoreHistories()
  func updateSelection(_ history: CustomerServiceDTO.ChatHistoriesHistory)
  func deleteHistories() async
}

extension CustomerServiceDTO.ChatHistoriesHistory: Identifiable { }

struct SelectedHistories {
  enum SelectMode {
    case include
    case exclude
  }
  
  var mode: SelectMode
  var selectedItems: [CustomerServiceDTO.ChatHistoriesHistory]
  var totalHistories: Int?
  
  var isSelectAll: Bool {
    isExcludeEmpty() || isIncludeAllItems()
  }
  
  private func isExcludeEmpty() -> Bool {
    mode == .exclude && selectedItems.isEmpty
  }
  
  private func isIncludeAllItems() -> Bool {
    guard let totalHistories else {
      return false
    }
    return mode == .include && selectedItems.count == totalHistories
  }
  
  var selectedButtonText: String {
    isSelectAll ? Localize
      .string("common_unselect_all") : Localize.string("common_select_all")
  }
  
  var deleteCount: Int {
    switch mode {
    case .include:
      return selectedItems.count
    case .exclude:
      guard let totalHistories else { return 0 }
      return totalHistories - selectedItems.count
    }
  }
  
  var deleteButtonText: String {
    if isSelectAll {
      return Localize.string("common_delete_all")
    }
    else if deleteCount > 0 {
      return Localize.string("common_delete") + "(\(deleteCount))"
    }
    else {
      return Localize.string("common_delete")
    }
  }
  
  mutating func toogle() {
    if isSelectAll {
      mode = .include
    }
    else {
      mode = .exclude
    }
    selectedItems = []
  }
  
  func isSelect(_ item: CustomerServiceDTO.ChatHistoriesHistory) -> Bool {
    switch mode {
    case .include:
      return selectedItems.contains(item)
    case .exclude:
      return !selectedItems.contains(item)
    }
  }
}

class ChatHistoriesEditViewModel:
  ErrorCollectViewModel,
  ChatHistoriesEditViewModelProtocol,
  ObservableObject
{
  @Published private(set) var histories: [CustomerServiceDTO.ChatHistoriesHistory] = []
  @Published private(set) var selectedHistories = SelectedHistories(mode: .include, selectedItems: [], totalHistories: nil)
  
  private let chatHistoryAppService: IChatHistoryAppService
  private let playerConfig: PlayerConfiguration
  
  private let pageSize = 20
  
  private var page = 1
  
  init(
    _ chatHistoryAppService: IChatHistoryAppService,
    _ playerConfig: PlayerConfiguration)
  {
    self.chatHistoryAppService = chatHistoryAppService
    self.playerConfig = playerConfig
  }
  
  func getChatHistory(_ page: Int) {
    AnyPublisher.from(chatHistoryAppService.getHistories(page: Int32(page), pageSize: Int32(pageSize)))
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [unowned self] in
        selectedHistories.totalHistories = Int($0.totalCount)
      })
      .map { [unowned self] in
        if let totalHistories = selectedHistories.totalHistories, totalHistories <= pageSize {
          return $0.histories
        }
        else {
          return selectedHistories.totalHistories == histories.count ? histories : histories + $0.histories
        }
      }
      .redirectErrors(to: self)
      .assign(to: &$histories)
  }
  
  func getMoreHistories() {
    if
      let totalHistories = selectedHistories.totalHistories, isMoreItemRemaining(
        itemsLoadedCount: histories.count,
        totalItems: totalHistories)
    {
      page += 1
      getChatHistory(page)
    }
  }
  
  private func isMoreItemRemaining(itemsLoadedCount: Int, totalItems: Int) -> Bool {
    itemsLoadedCount < totalItems
  }
  
  func updateSelection(_ history: CustomerServiceDTO.ChatHistoriesHistory) {
    if let index = selectedHistories.selectedItems.firstIndex(of: history) {
      selectedHistories.selectedItems.remove(at: index)
    }
    else {
      selectedHistories.selectedItems.append(history)
    }
  }
  
  func deleteHistories() async {
    await AnyPublisher
      .from(
        chatHistoryAppService
          .deletes(chatHistories: selectedHistories.selectedItems, isExclude: selectedHistories.mode == .exclude))
      .redirectErrors(to: self)
      .valueWithoutError
  }
  
  func toggleSelectAll() {
    selectedHistories.toogle()
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfig.supportLocale
  }
}
