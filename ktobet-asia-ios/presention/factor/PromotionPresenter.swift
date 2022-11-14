import Foundation
import UIKit
import SharedBu

class PromotionPresenter: FilterPresentProtocol {
    static let sortingRow = 1
    static let productRows = 4...8
    
    private let productAllRow = 3
    private let bonusRows = 9...12
    
    func getTitle() -> String {
        return Localize.string("common_filter")
    }
    func setConditions(_ items: [FilterItem]) {
        conditions = items as! [PromotionItem]
    }
    func getDatasource() -> [FilterItem] {
        return conditions
    }
    func itemText(_ item: FilterItem) -> String {
        return (item as! PromotionItem).title
    }
    func itemAccenery(_ item: FilterItem) -> Any? {
        return (item as! PromotionItem).image
    }
    func toggleItem(_ row: Int) {
        if row == PromotionPresenter.sortingRow {
            if let sortingType = conditions[row].sortingType {
                switch sortingType {
                case .desc:
                    conditions[row].title = Localize.string("bonus_orderby_asc")
                    conditions[row].sortingType = .asc
                case .asc:
                    conditions[row].title = Localize.string("bonus_orderby_desc")
                    conditions[row].sortingType = .desc
                }
            }
            
            return
        }
        
        // at least one row is selected
        let allSelectCount = conditions[4..<conditions.count].filter({ $0.isSelected == true }).count
        if allSelectCount <= 1, conditions[row].isSelected == true { return }

        if row == productAllRow {
            // at least one bouns type is selected, if productAllRow deselected
            let allBonusCount = conditions[bonusRows].filter({ $0.isSelected == true }).count
            if allBonusCount <= 0, conditions[row].isSelected == true { return }

            if let selected = conditions[row].isSelected {
                if selected {
                    for index in conditions[PromotionPresenter.productRows].indices {
                        conditions[index].isSelected = false
                    }
                } else {
                    for index in conditions[PromotionPresenter.productRows].indices {
                        conditions[index].isSelected = true
                    }
                }
            }
        }
        
        if PromotionPresenter.productRows.contains(row) {
            // at least one product is selected.
            let allProductCount = conditions[PromotionPresenter.productRows].filter({ $0.isSelected == true }).count
            if allProductCount <= 1, conditions[row].isSelected == true { return }
            
            if !conditions[row].isSelected! && allProductCount == 4 {
                conditions[productAllRow].isSelected = true
            } else {
                (conditions[safe: productAllRow] as! ProductPromotionItem).selected = .some
            }
        }
        
        conditions[row].isSelected?.toggle()
    }
    
    func getConditionStatus(_ items: [PromotionItem]) -> (prodcutType: [ProductType], bonusType: [BonusType], sorting: SortingType) {
        let productTypes = items.filter({ $0.isSelected == true }).compactMap{ $0.productType }
        var bonusTypes = items.filter({ $0.isSelected == true }).compactMap{ $0.bonusType }
        let sortingType = (items.filter({ $0.sortingType != nil }).first?.sortingType)!
        if !productTypes.isEmpty {
            bonusTypes.append(BonusType.product)
        }
        
        if bonusTypes.filter({ $0 == BonusType.depositbonus }).count != 0 {
            bonusTypes.append(BonusType.levelbonus)
        }
        
        return (productTypes, bonusTypes, sortingType)
    }
    
    private var conditions: [PromotionItem] =
        [PromotionPresenter.createStaticDisplay(Localize.string("bonus_custom_sorting")),
         PromotionPresenter.createInteractive(.desc),
         PromotionPresenter.createStaticDisplay(Localize.string("bonus_custom_filter")),
         PromotionPresenter.createProductPromotionItem(),
         PromotionPresenter.createInteractive(.sbk),
         PromotionPresenter.createInteractive(.slot),
         PromotionPresenter.createInteractive(.casino),
         PromotionPresenter.createInteractive(.numbergame),
         PromotionPresenter.createInteractive(.arcade),
         PromotionPresenter.createInteractive(.rebate),
         PromotionPresenter.createInteractive(.freebet),
         PromotionPresenter.createInteractive(.depositbonus),
         PromotionPresenter.createInteractive(.vvipcashback)]

    
    class func createStaticDisplay(_ title: String) -> PromotionItem {
        return PromotionItem(type: .static, title: title, select: false)
    }
    
    class func createProductPromotionItem() -> ProductPromotionItem {
        return ProductPromotionItem(type: .interactive,
                                    title: StringMapper.parseProductTypeString(productType: .none),
                                    select: true,
                                    productType: ProductType.none)
    }
    
    class func createInteractive(_ productType: ProductType) -> PromotionItem {
        return PromotionItem(type: .interactive,
                             title: StringMapper.parseProductTypeString(productType: productType),
                             select: true,
                             productType: productType)
    }
    
    class func createInteractive(_ bonusType: BonusType) -> PromotionItem {
        return PromotionItem(type: .interactive,
                             title: StringMapper.parseBonusTypeString(bonusType: bonusType),
                             select: true,
                             bonusType: bonusType)
    }
    
    class func createInteractive(_ sortingType: SortingType) -> PromotionItem {
        return PromotionItem(type: .interactive,
                             title: StringMapper.getPromotionSortingTypeString(sortingType: sortingType),
                             select: true,
                             sortingType: sortingType)
    }
}

class ProductPromotionItem: PromotionItem {
    enum SelectState {
        case all
        case some
        case none
    }
    override var isSelected: Bool? {
        set {
            guard newValue != nil else { return }
            selected = newValue! ? .all : .none
        }
        get {
            switch selected {
            case .all:
                return true
            case .none, .some:
                return false
            }
        }
    }
    var selected: SelectState = .all
    override var image: UIImage? {
        switch selected {
        case .all:
            return UIImage(named: "iconDoubleSelectionSelected24")
        case .some:
            return UIImage(named: "iconDoubleSelectionSelected5024")
        case .none:
            return UIImage(named: "iconDoubleSelectionEmpty24")
        }
    }
}

class PromotionItem: FilterItem {
    var type: Display
    var title: String
    var sortingType: SortingType?
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

    private var _bonusType: BonusType?
    var bonusType: BonusType? {
        switch type {
        case .static:
            return nil
        case .interactive:
            return _bonusType
        }
    }

    private var _productType: ProductType?
    var productType: ProductType? {
        switch type {
        case .static:
            return nil
        case .interactive:
            return _productType
        }
    }
    
    var image: UIImage? {
        if let _ = sortingType {
            return UIImage(named: "iconArrowDropDown16")
        }
        return select ?? false ? UIImage(named: "iconDoubleSelectionSelected24") : UIImage(named: "iconDoubleSelectionEmpty24")
    }
    
    init(type: Display, title: String, select: Bool, bonusType: BonusType? = nil, productType: ProductType? = nil, sortingType: SortingType? = nil) {
        self.type = type
        self.title = title
        self.select = select
        self._bonusType = bonusType
        self._productType = productType
        self.sortingType = sortingType
    }
}

enum SortingType: String {
    case desc = "Desc", asc = "Asc"
}
