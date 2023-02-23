import SharedBu
import UIKit

class DepositPresenter {
  private var conditions: [DepositTransactionItem] = [
    DepositPresenter.create(.static),
    DepositPresenter.create(.interactive, .approved),
    DepositPresenter.create(.interactive, .reject),
    DepositPresenter.create(.interactive, .pending),
    DepositPresenter.create(.interactive, .floating)
  ]

  func getConditionStatus(_ items: [DepositTransactionItem]) -> [PaymentLogDTO.LogStatus] {
    items.filter({ $0.isSelected == true }).map({ $0.status! })
  }

  class func create(_ category: Display, _ status: PaymentLogDTO.LogStatus? = nil) -> DepositTransactionItem {
    switch category {
    case .static:
      return DepositTransactionItem(type: .static, title: Localize.string("common_statusfilter"), select: false)
    case .interactive:
      return DepositTransactionItem(
        type: .interactive,
        title: status == nil ? "" : DepositPresenter.title(status!),
        select: true,
        status: status)
    }
  }

  class func title(_ status: PaymentLogDTO.LogStatus) -> String {
    switch status {
    case .floating:
      return Localize.string("common_floating")
    case .pending:
      return Localize.string("common_processing")
    case .reject:
      return Localize.string("common_fail")
    case .approved:
      return Localize.string("common_success")
    default:
      return ""
    }
  }
}

extension DepositPresenter: FilterPresentProtocol {
  func getTitle() -> String {
    Localize.string("common_filter")
  }

  func setConditions(_ items: [FilterItem]) {
    conditions = items as! [DepositTransactionItem]
  }

  func getDatasource() -> [FilterItem] {
    conditions
  }

  func itemText(_ item: FilterItem) -> String {
    (item as! DepositTransactionItem).title
  }

  func itemAccenery(_ item: FilterItem) -> Any? {
    (item as! DepositTransactionItem).image
  }

  func toggleItem(_ row: Int) {
    let allSelectCount = conditions.filter({ $0.isSelected == true }).count
    /// The last one condition cloud not be unSelect.
    if allSelectCount <= 1, conditions[row].isSelected == true { return }
    conditions[row].isSelected?.toggle()
  }

  func getSelectedTitle(_: [FilterItem]) -> String { "" }
  func getSelectedItems(_: [FilterItem]) -> [FilterItem] { [] }
}

struct DepositTransactionItem: FilterItem {
  var type: Display
  var title: String
  private var select: Bool? = false
  var isSelected: Bool? {
    set {
      select = newValue
    }
    get {
      switch type {
      case .static:
        return nil
      case .interactive:
        return select
      }
    }
  }

  var image: UIImage? {
    select ?? false ? UIImage(named: "Double Selection (Selected)") : UIImage(named: "Double Selection (Empty)")
  }

  init(type: Display, title: String, select: Bool, status: PaymentLogDTO.LogStatus? = nil) {
    self.type = type
    self.title = title
    self.select = select
    self._status = status
  }

  private var _status: PaymentLogDTO.LogStatus?
  var status: PaymentLogDTO.LogStatus? {
    switch type {
    case .static:
      return nil
    case .interactive:
      return _status
    }
  }
}

struct TransactionItem: FilterItem {
  var type: Display
  var title: String
  private var select: Bool? = false
  var isSelected: Bool? {
    set {
      select = newValue
    }
    get {
      switch type {
      case .static:
        return nil
      case .interactive:
        return select
      }
    }
  }

  var image: UIImage? {
    select ?? false ? UIImage(named: "Double Selection (Selected)") : UIImage(named: "Double Selection (Empty)")
  }

  init(type: Display, title: String, select: Bool, status: TransactionStatus? = nil) {
    self.type = type
    self.title = title
    self.select = select
    self._status = status
  }

  private var _status: TransactionStatus?
  var status: TransactionStatus? {
    switch type {
    case .static:
      return nil
    case .interactive:
      return _status
    }
  }
}
