import Foundation
import sharedbu
import UIKit

class StringMapper {
  static func getPromotionSortingTypeString(sortingType: SortingType) -> String {
    switch sortingType {
    case .asc:
      return Localize.string("bonus_orderby_asc")
    case .desc:
      return Localize.string("bonus_orderby_desc")
    }
  }

  static func parseProductTypeString(productType: ProductType) -> String {
    switch productType {
    case .sbk:
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
    case .none:
      return Localize.string("bonus_bonustype_3")
    }
  }

  static func parseBonusTypeString(bonusType: BonusType) -> String {
    switch bonusType {
    case .rebate:
      return Localize.string("common_rebate")
    case .freeBet:
      return Localize.string("common_freebet")
    case .depositBonus,
         .levelBonus:
      return Localize.string("common_depositbonus")
    case .product:
      return Localize.string("bonus_bonustype_3")
    case .vvipcashback:
      return Localize.string("bonus_bonustype_7")
    case .other:
      return ""
    }
  }

  static func parseprivilegeTypeTypeString(privilegeType: PrivilegeType) -> String {
    switch privilegeType {
    case .rebate:
      return Localize.string("common_rebate")
    case .freebet:
      return Localize.string("common_freebet")
    case .depositBonus,
         .levelBonus:
      return Localize.string("common_depositbonus")
    case .product:
      return Localize.string("bonus_bonustype_3")
    case .vvipcashBack:
      return Localize.string("bonus_bonustype_7")
    case .domain,
         .feedback,
         .none,
         .withdrawal:
      return ""
    }
  }

  static func parse(bonusReceivingStatus: BonusReceivingStatus) -> String {
    switch bonusReceivingStatus {
    case .noTurnOver:
      return Localize.string("bonus_bonuslockstatus_0")
    case .inProgress:
      return Localize.string("bonus_bonuslockstatus_1")
    case .completed:
      return Localize.string("bonus_bonuslockstatus_2")
    case .canceled:
      return Localize.string("bonus_bonuslockstatus_3")
    }
  }
}
