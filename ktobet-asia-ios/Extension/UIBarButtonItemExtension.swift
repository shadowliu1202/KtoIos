import RxSwift
import sharedbu
import UIKit

extension UIBarButtonItem {
  static func kto(
    _ ktoStyle: KTOBarButtonItemStyle,
    style _: UIBarButtonItem.Style = .plain,
    target _: Any? = nil,
    action _: Selector? = nil)
    -> UIBarButtonItem
  {
    switch ktoStyle {
    case .record:
      return RecordBarButtonItem()
    case .favorite:
      return FavoriteBarButtonItem()
    case .search:
      return SearchButtonItem()
    case .filter:
      return FilterBarButtonItem()
    case .text(let text):
      return TextBarButtonItem(title: text)
    case .history:
      return HistoryBarButtonItem()
    case .close:
      return CloseBarButtonItem()
    case .customIamge(let name):
      return CustomImageBarButtonItem(imgName: name)
    case .cs(
      let supportLocale,
      let customerServiceViewModel,
      let serviceStatusViewModel,
      let alert,
      let delegate,
      let disposeBag):
      return CustomerServiceButtonItem.create(
        by: supportLocale,
        customerServiceViewModel: customerServiceViewModel,
        serviceStatusViewModel: serviceStatusViewModel,
        alert: alert,
        delegate,
        disposeBag)
    case .register:
      return RegisterButtonItem()
    case .login:
      return LoginButtonItem()
    case .manulUpdate:
      return ManualUpdateButtonItem()
    }
  }

  func actionHandler(_ action: @escaping (UIBarButtonItem) -> Void) {
    let sleeve = ClosureSleeve(self, action)
    self.target = sleeve
    self.action = #selector(ClosureSleeve.invoke)
    objc_setAssociatedObject(
      self,
      String(format: "[%d]", arc4random()),
      sleeve,
      objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
  }

  func isEnable(_ isEnable: Bool) -> UIBarButtonItem {
    self.isEnabled = isEnable
    return self
  }

  @discardableResult
  func senderId(_ id: Int) -> UIBarButtonItem {
    self.tag = id
    return self
  }

  @IBInspectable public var localizeTitle: String? {
    get { title }
    set { title = newValue == nil ? nil : Localize.string(newValue!) }
  }
}

enum KTOBarButtonItemStyle {
  case record
  case favorite
  case search
  case filter
  case text(text: String)
  case history
  case close
  case customIamge(named: String)
  case cs(
    supportLocale: SupportLocale,
    customerServiceViewModel: CustomerServiceViewModel,
    serviceStatusViewModel: ServiceStatusViewModel,
    alert: AlertProtocol,
    delegate: CustomServiceDelegate,
    disposeBag: DisposeBag)
  case register
  case login
  case manulUpdate

  var image: UIImage? {
    switch self {
    case .record: return UIImage(named: "Record")
    case .favorite: return UIImage(named: "Favorite")
    case .search: return UIImage(named: "Search")
    case .filter: return UIImage(named: "iconFilter24")
    case .cs,
         .login,
         .manulUpdate,
         .register,
         .text: return nil
    case .history: return UIImage(named: "iconNavPromotionHistory24")
    case .close: return UIImage(named: "Close")
    case .customIamge(let name): return UIImage(named: name)
    }
  }
}

@objc
class ClosureSleeve: NSObject {
  let item: UIBarButtonItem
  let closure: (UIBarButtonItem) -> Void

  init(_ item: UIBarButtonItem, _ closure: @escaping (UIBarButtonItem) -> Void) {
    self.item = item
    self.closure = closure
  }

  @objc
  func invoke() {
    closure(item)
  }
}
