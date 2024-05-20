import Foundation
import sharedbu

class LevelPrivilegeResourceMapper: PrivilegeResource {
    func privilegeTitleMapper() -> ResourceIdMapper {
        TitleIdMapper()
    }

    func privilegeSubTitleMapper() -> ResourceIdMapper {
        SubTitleIdMapper()
    }

    func productPrivilegeSubtitleMapper() -> ResourceIdMapper {
        ProductSubtitleIdMapper()
    }

    func descriptionTemplateFactory() -> PrivilegeDescriptionFactory {
        PrivilegeDescriptionImpl()
    }
}

class TitleIdMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
        guard let type = item as? PrivilegeType else {
            return ResourceKey(key: "")
        }
        switch type {
        case .product:
            return ResourceKey(key: "level_privilegetype_3")
        case .rebate:
            return ResourceKey(key: "level_privilegetype_4")
        case .levelBonus:
            return ResourceKey(key: "level_privilegetype_5")
        case .feedback:
            return ResourceKey(key: "level_privilegetype_90")
        case .withdrawal:
            return ResourceKey(key: "level_privilegetype_91")
        case .domain:
            return ResourceKey(key: "level_privilegetype_90")
        case .depositBonus,
             .freebet,
             .none,
             .vvipcashBack:
            return ResourceKey(key: "")
        }
    }
}

class SubTitleIdMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
        guard let type = item as? PrivilegeType else {
            return ResourceKey(key: "")
        }
        switch type {
        case .feedback:
            return ResourceKey(key: "level_exclusive_90")
        case .depositBonus,
             .domain,
             .freebet,
             .levelBonus,
             .none,
             .product,
             .rebate,
             .vvipcashBack,
             .withdrawal:
            return ResourceKey(key: "")
        }
    }
}

class ProductSubtitleIdMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
        guard let type = item as? ProductType else {
            return ResourceKey(key: "")
        }
        switch type {
        case .sbk:
            return ResourceKey(key: "level_producttype_1")
        case .slot:
            return ResourceKey(key: "level_producttype_2")
        case .arcade,
             .casino,
             .none,
             .numberGame,
             .p2P:
            return ResourceKey(key: "")
        }
    }
}

class PrivilegeDescriptionImpl: PrivilegeDescriptionFactory {
    func createProductTemplate(productType: ProductType?) -> PrivilegeDescriptionFactoryLeveLDescriptionResource {
        ProductTypeDescriptionResourceIdMapper(productType)
    }

    func createTemplate(privilegeType: PrivilegeType) -> PrivilegeDescriptionFactoryLeveLDescriptionResource {
        PrivilegeTypeDescriptionResourceIdMapper(privilegeType)
    }
}

class ProductTypeDescriptionResourceIdMapper: PrivilegeDescriptionFactoryLeveLDescriptionResource {
    var productType: ProductType?

    init(_ productType: ProductType?) {
        self.productType = productType
    }

    func template() -> ResourceIdMapper {
        guard let productType else { return PrivilegeDescription.Product.Empty() }
        switch productType {
        case .sbk:
            return PrivilegeDescription.Product.SBK()
        case .slot:
            return PrivilegeDescription.Product.Slot()
        case .arcade,
             .casino,
             .none,
             .numberGame,
             .p2P: return PrivilegeDescription.Product.Empty()
        }
    }
}

class PrivilegeTypeDescriptionResourceIdMapper: PrivilegeDescriptionFactoryLeveLDescriptionResource {
    var privilegeType: PrivilegeType

    init(_ privilegeType: PrivilegeType) {
        self.privilegeType = privilegeType
    }

    func template() -> ResourceIdMapper {
        switch privilegeType {
        case .rebate:
            return PrivilegeDescription.Rebate()
        case .levelBonus:
            return PrivilegeDescription.LevelBonus()
        case .feedback:
            return PrivilegeDescription.Feedback()
        case .withdrawal:
            return PrivilegeDescription.Withdrawal()
        case .domain:
            return PrivilegeDescription.Domain()
        case .depositBonus,
             .freebet,
             .none,
             .vvipcashBack:
            return PrivilegeDescription.Empty()
        case .product:
            return PrivilegeDescription.Product.Empty()
        }
    }
}

class PrivilegeDescription {
    class Rebate: ResourceIdMapper {
        func map(item: Any?) -> ResourceKey {
            guard let level = item as? Int32 else {
                return ResourceKey(key: "")
            }
            switch level {
            case 1,
                 4,
                 7:
                return ResourceKey(key: "level_4")
            case 9:
                return ResourceKey(key: "level_4_leveltop")
            default:
                return ResourceKey(key: "")
            }
        }
    }

    class LevelBonus: ResourceIdMapper {
        func map(item: Any?) -> ResourceKey {
            guard let level = item as? Int32 else {
                return ResourceKey(key: "")
            }
            switch level {
            case 1:
                return ResourceKey(key: "level_5_0_level1")
            case 2:
                return ResourceKey(key: "level_5_0_level2")
            case 3,
                 5:
                return ResourceKey(key: "level_5_1")
            case 6:
                return ResourceKey(key: "level_5_2")
            case 8:
                return ResourceKey(key: "level_5_4")
            case 10:
                return ResourceKey(key: "level_5_3")
            default:
                return ResourceKey(key: "")
            }
        }
    }

    class Feedback: ResourceIdMapper {
        func map(item _: Any?) -> ResourceKey {
            ResourceKey(key: "level_90")
        }
    }

    class Withdrawal: ResourceIdMapper {
        func map(item: Any?) -> ResourceKey {
            guard let level = item as? Int32 else {
                return ResourceKey(key: "")
            }
            switch level {
            case 1:
                return ResourceKey(key: "level_91")
            case 10:
                return ResourceKey(key: "level_91_leveltop")
            default:
                return ResourceKey(key: "")
            }
        }
    }

    class Domain: ResourceIdMapper {
        func map(item _: Any?) -> ResourceKey {
            ResourceKey(key: "level_privilegetype_92")
        }
    }

    class Empty: ResourceIdMapper {
        func map(item _: Any?) -> ResourceKey {
            ResourceKey(key: "")
        }
    }

    class Product {
        class SBK: ResourceIdMapper {
            func map(item: Any?) -> ResourceKey {
                guard let level = item as? Int32 else {
                    return ResourceKey(key: "")
                }
                switch level {
                case 1,
                     3,
                     5,
                     7:
                    return ResourceKey(key: "level_3_1")
                case 9:
                    return ResourceKey(key: "level_3_1_leveltop")
                default:
                    return ResourceKey(key: "")
                }
            }
        }

        class Slot: ResourceIdMapper {
            func map(item: Any?) -> ResourceKey {
                guard let level = item as? Int32 else {
                    return ResourceKey(key: "")
                }
                switch level {
                case 1,
                     3,
                     5,
                     7:
                    return ResourceKey(key: "level_3_2")
                case 9:
                    return ResourceKey(key: "level_3_2_leveltop")
                default:
                    return ResourceKey(key: "")
                }
            }
        }

        class Empty: ResourceIdMapper {
            func map(item _: Any?) -> ResourceKey {
                ResourceKey(key: "")
            }
        }
    }
}
