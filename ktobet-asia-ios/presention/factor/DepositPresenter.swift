import UIKit
import share_bu

class DepositPresenter {
    private var conditions: [TransactionItem] = [FilterItemFactor.create(.static),
                              FilterItemFactor.create(.interactive, .approved),
                              FilterItemFactor.create(.interactive, .reject),
                              FilterItemFactor.create(.interactive, .pending),
                              FilterItemFactor.create(.interactive, .floating)]
    
    func getConditionStatus(_ items: [TransactionItem]) -> [TransactionStatus] {
        return items.filter({ $0.isSelected == true }).map({$0.status!})
    }
}

extension DepositPresenter: FilterPresentProtocol {
    func getTitle() -> String {
        return Localize.string("common_filter")
    }
    func setConditions(_ items: [FilterItem]) {
        conditions = items as! [TransactionItem]
    }
    func getDatasource() -> [FilterItem] {
        return conditions
    }
    func itemText(_ item: FilterItem) -> String {
        return (item as! TransactionItem).title
    }
    func itemAccenery(_ item: FilterItem) -> Any? {
        return (item as! TransactionItem).image
    }
    func toggleItem(_ row: Int) {
        let allSelectCount = conditions.filter({ $0.isSelected == true }).count
        ///The last one condition cloud not be unSelect.
        if allSelectCount <= 1, conditions[row].isSelected == true { return }
        conditions[row].isSelected?.toggle()
    }
}

class FilterItemFactor {
    class func create(_ category: Display, _ status: TransactionStatus? = nil) -> TransactionItem {
        switch category {
        case .static:
            return TransactionItem(type: .static, title: Localize.string("common_statusfilter"), select: false)
        case .interactive:
            return TransactionItem(type: .interactive,
                                   title: status == nil ? "" : TransactionStatusFactor.title(status!),
                                   select: true,
                                   status: status)
        }
    }
}

struct TransactionItem: FilterItem {
    var type: Display
    var title: String
    private var select: Bool? = false
    var isSelected: Bool? {
        set{
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
        return select ?? false ? UIImage(named: "Double Selection (Selected)") : UIImage(named: "Double Selection (Empty)")
    }
    
    init(type: Display, title: String, select: Bool, status: TransactionStatus? = nil ) {
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
