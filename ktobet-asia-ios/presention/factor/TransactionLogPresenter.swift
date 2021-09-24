import Foundation
import UIKit
import SharedBu

class TransactionLogPresenter: FilterPresentProtocol {
    func getTitle() -> String {
        return Localize.string("common_filter")
    }
    func setConditions(_ items: [FilterItem]) {
        conditions = items as! [TransactionLogItem]
    }
    func getDatasource() -> [FilterItem] {
        return conditions
    }
    func itemText(_ item: FilterItem) -> String {
        return (item as! TransactionLogItem).title
    }
    func itemAccenery(_ item: FilterItem) -> Any? {
        return (item as! TransactionLogItem).image
    }
    func toggleItem(_ row: Int) {
        if row == 0 {
            if conditions[0].isAllSelected {
                conditions.indices.forEach{ conditions[$0].isSelected = false }
                conditions.indices.forEach{ conditions[$0].isAllSelected = false }
                conditions[1].isSelected? = true
            } else {
                conditions.indices.forEach{ conditions[$0].isSelected = true }
                conditions.indices.forEach{ conditions[$0].isAllSelected = true }
            }
            
            conditions[0].isSelected?.toggle()
        } else {
            conditions.indices.forEach{ conditions[$0].isAllSelected = false }
            conditions.indices.forEach{ conditions[$0].isSelected = false }
            conditions[row].isSelected = true
            conditions[0].isSelected = true
        }
    }
    
    func getConditionStatus(_ items: [TransactionLogItem]) -> CashLogFilter {
        let transactionTypes = items.filter({ $0.isSelected == true }).compactMap{ $0.transactionTypes }
        return transactionTypes.count == conditions.count - 1 ? CashLogFilter.all : transactionTypes.first!
    }
    
    private var conditions: [TransactionLogItem] =
        [TransactionLogPresenter.createStaticDisplay(Localize.string("balancelog_categoryfilter")),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_deposit"), .deposit),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_withdrawal"), .withdrawal),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_sportsbook"), .sportsBook),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_slot"), .slot),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_casino"), .casino),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_keno"), .numberGame),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_p2p"), .p2P),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_arcade"), .arcade),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_adjustment"), .adjustment),
         TransactionLogPresenter.createInteractive(title: Localize.string("common_bonus"), .bonus),]

    
    class func createStaticDisplay(_ title: String) -> TransactionLogItem {
        return TransactionLogItem(type: .static, title: title, select: false)
    }
    
    class func createInteractive(title: String, _ transactionTypes: CashLogFilter) -> TransactionLogItem {
        return TransactionLogItem(type: .interactive,
                             title: title,
                             select: true,
                             transactionTypes: transactionTypes)
    }
}

struct TransactionLogItem: FilterItem {
    var type: Display
    var title: String
    private var select: Bool? = true
    var isSelected: Bool? {
        set{
            select = newValue
        }
        get {
            switch type {
            case .static:
                return select
            case .interactive:
                return select
            }
        }
    }
    var isAllSelected: Bool = true
    var image: UIImage? {
        if select ?? false {
            let img = isAllSelected ? UIImage(named: "iconDoubleSelectionSelected24") : UIImage(named: "iconSingleSelectionSelected24")
            return img
        } else {
            return UIImage(named: "iconSingleSelectionEmpty24")
        }
        
        
    }
    
    init(type: Display, title: String, select: Bool, transactionTypes: CashLogFilter? = nil) {
        self.type = type
        self.title = title
        self.select = select
        self._transactionTypes = transactionTypes
    }
    private var _transactionTypes: CashLogFilter?
    var transactionTypes: CashLogFilter? {
        switch type {
        case .static:
            return nil
        case .interactive:
            return _transactionTypes
        }
    }
}

enum CashLogFilter: Int {
    case all = 0
    case deposit = 1
    case withdrawal = 2
    case sportsBook = 3
    case slot = 4
    case casino = 5
    case numberGame = 8
    case p2P = 9
    case arcade = 10
    case adjustment = 6
    case bonus = 7
}
