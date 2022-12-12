import Foundation
import UIKit
import SharedBu

class TransactionLogPresenter: FilterPresentProtocol,
                               ObservableObject {
    
    private var conditions: [Item] = TransactionType
        .allCases
        .map {
            .init(
                type: $0 == .all ? .static : .interactive,
                title: $0.title,
                isSelected: $0 == .all ? false : true,
                transactionType: $0
            )
        }
    
    func getTitle() -> String { Localize.string("common_filter") }
    
    func getDatasource() -> [FilterItem] { conditions }
    
    func itemText(_ item: FilterItem) -> String { item.title }
    
    func itemAccenery(_ item: FilterItem) -> Any? { (item as? Item)?.image }
    
    func setConditions(_ items: [FilterItem]) {
        conditions = items.compactMap { $0 as? Item }
    }
    
    func toggleItem(_ row: Int) {
        if row == 0 {
            let staticSelected = conditions[row].isAllSelected
            
            conditions
                .indices
                .forEach {
                    conditions[$0].isSelected = !staticSelected
                    conditions[$0].isAllSelected = !staticSelected
                }
        }
        else {
            conditions
                .indices
                .forEach {
                    conditions[$0].isSelected = false
                    conditions[$0].isAllSelected = false
                }
            
            conditions[row].isSelected = true
        }
        
        conditions[0].isSelected?.toggle()
    }
        
    func getSelectedItems(_ items: [FilterItem]) -> [FilterItem] {
        if let all = items.first(where: { $0.isSelected == false && $0.type == .static }) {
            return [all]
        }
        else {
            return items.filter { $0.isSelected == true && $0.type != .static }
        }
    }
    
    func getSelectedTitle(_ items: [FilterItem]) -> String {
        let selected = getSelectedItems(items)
        
        if selected.first?.type == .static {
            return Localize.string("common_all")
        }
        else {
            return selected
                .compactMap { $0.title }
                .joined(separator: "/")
        }
    }
    
    func getConditionStatus(_ items: [Item]) -> TransactionType {
        (getSelectedItems(items).first as? Item)?.transactionType ?? .all
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - Model

extension TransactionLogPresenter {
    
    enum TransactionType: Int, CaseIterable {
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
        
        var title: String {
            switch self {
            case .all:
                return Localize.string("balancelog_categoryfilter")
            case .deposit:
                return Localize.string("common_deposit")
            case .withdrawal:
                return Localize.string("common_withdrawal")
            case .sportsBook:
                return Localize.string("common_sportsbook")
            case .slot:
                return Localize.string("common_slot")
            case .casino:
                return Localize.string("common_casino")
            case .numberGame:
                return Localize.string("common_keno")
            case .p2P:
                return Localize.string("common_p2p")
            case .arcade:
                return Localize.string("common_arcade")
            case .adjustment:
                return Localize.string("common_adjustment")
            case .bonus:
                return Localize.string("common_bonus")
            }
        }
    }
    
    struct Item: FilterItem {
        var type: Display
        var title: String
        var isSelected: Bool? = true
        var isAllSelected: Bool = true
        var transactionType: TransactionType
        
        var image: UIImage? {
            if isSelected ?? false {
                let img = isAllSelected ? UIImage(named: "iconDoubleSelectionSelected24") : UIImage(named: "iconSingleSelectionSelected24")
                return img
            } else {
                return UIImage(named: "iconSingleSelectionEmpty24")
            }
        }
        
        init(
            type: Display,
            title: String,
            isSelected: Bool,
            transactionType: TransactionType
        ) {
            self.type = type
            self.title = title
            self.isSelected = isSelected
            self.transactionType = transactionType
        }
    }
}
