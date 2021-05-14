import UIKit


extension UIBarButtonItem {
    static func kto(_ ktoStyle: KTOBarButtonItemStyle, style: UIBarButtonItem.Style = .plain, target: Any? = nil, action: Selector? = nil) -> UIBarButtonItem {
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
        }
    }
    
    func actionHandler(_ action: @escaping (UIBarButtonItem) -> Void) {
        let sleeve = ClosureSleeve(self, action)
        self.target = sleeve
        self.action = #selector(ClosureSleeve.invoke)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

enum KTOBarButtonItemStyle {
    case record
    case favorite
    case search
    case filter
    case text(text: String)
    
    var image: UIImage? {
        switch self {
        case .record:           return UIImage(named: "Record")
        case .favorite:         return UIImage(named: "Favorite")
        case .search:           return UIImage(named: "Search")
        case .filter:           return UIImage(named: "iconFilter24")
        case .text:             return nil
        }
    }
}

@objc class ClosureSleeve: NSObject {
    let item : UIBarButtonItem
    let closure: (UIBarButtonItem) -> ()

    init (_ item: UIBarButtonItem, _ closure: @escaping (UIBarButtonItem) -> ()) {
        self.item = item
        self.closure = closure
    }

    @objc func invoke () {
        closure(item)
    }
}
