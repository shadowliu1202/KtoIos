import UIKit

protocol FilterPresentProtocol {
  func getTitle() -> String
  func getDatasource() -> [FilterItem]
  func setConditions(_ items: [FilterItem])
  func itemText(_ item: FilterItem) -> String
  func itemAccenery(_ item: FilterItem) -> Any?
  func toggleItem(_ row: Int)
  func getSelectedItems(_ items: [FilterItem]) -> [FilterItem]
  func getSelectedTitle(_ items: [FilterItem]) -> String
}

protocol FilterItem {
  var type: Display { get }
  var title: String { get }
  var isSelected: Bool? { set get }
}

enum Display: Equatable {
  case `static`
  case interactive
  static func == (lhs: Display, rhs: Display) -> Bool {
    switch (lhs, rhs) {
    case (.static, .static):
      return true
    case (.interactive, .interactive):
      return true
    default:
      return false
    }
  }
}
