import Foundation
import UIKit
import share_bu

class WithdrawalPresenter: FilterPresentProtocol {
    private var conditions: [TransactionItem] = [FilterItemFactor.create(.static),
                              FilterItemFactor.create(.interactive, .approved),
                              FilterItemFactor.create(.interactive, .reject),
                              FilterItemFactor.create(.interactive, .pending),
                              FilterItemFactor.create(.interactive, .floating),
                              FilterItemFactor.create(.interactive, .cancel)]
    
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
    func getConditionStatus(_ items: [TransactionItem]) -> [TransactionStatus] {
        return items.filter({ $0.isSelected == true }).map({$0.status!})
    }
}
