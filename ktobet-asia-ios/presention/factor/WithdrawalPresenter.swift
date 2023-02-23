import Foundation
import SharedBu
import UIKit

class WithdrawalPresenter: FilterPresentProtocol {
  private var conditions: [TransactionItem] = [
    WithdrawalPresenter.create(.static),
    WithdrawalPresenter.create(.interactive, .approved),
    WithdrawalPresenter.create(.interactive, .reject),
    WithdrawalPresenter.create(.interactive, .pending),
    WithdrawalPresenter.create(.interactive, .floating),
    WithdrawalPresenter.create(.interactive, .cancel)
  ]

  func getTitle() -> String {
    Localize.string("common_filter")
  }

  func setConditions(_ items: [FilterItem]) {
    conditions = items as! [TransactionItem]
  }

  func getDatasource() -> [FilterItem] {
    conditions
  }

  func itemText(_ item: FilterItem) -> String {
    (item as! TransactionItem).title
  }

  func itemAccenery(_ item: FilterItem) -> Any? {
    (item as! TransactionItem).image
  }

  func toggleItem(_ row: Int) {
    let allSelectCount = conditions.filter({ $0.isSelected == true }).count
    /// The last one condition cloud not be unSelect.
    if allSelectCount <= 1, conditions[row].isSelected == true { return }
    conditions[row].isSelected?.toggle()
  }

  func getConditionStatus(_ items: [TransactionItem]) -> [TransactionStatus] {
    items.filter({ $0.isSelected == true }).map({ $0.status! })
  }

  class func create(_ category: Display, _ status: TransactionStatus? = nil) -> TransactionItem {
    switch category {
    case .static:
      return TransactionItem(type: .static, title: Localize.string("common_statusfilter"), select: false)
    case .interactive:
      return TransactionItem(
        type: .interactive,
        title: status == nil ? "" : WithdrawalPresenter.title(status!),
        select: true,
        status: status)
    }
  }

  class func title(_ status: TransactionStatus) -> String {
    switch status {
    case .floating:
      return Localize.string("common_floating")
    case .pending:
      return Localize.string("common_pending_or_pending_hold")
    case .reject:
      return Localize.string("common_reject")
    case .approved:
      return Localize.string("common_success")
    case .cancel:
      return Localize.string("common_cancel")
    default:
      return ""
    }
  }

  func getSelectedTitle(_: [FilterItem]) -> String { "" }
  func getSelectedItems(_: [FilterItem]) -> [FilterItem] { [] }
}
