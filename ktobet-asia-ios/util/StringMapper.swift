import Foundation
import SharedBu
import UIKit

class StringMapper {
  @available(*, deprecated, message: "Delete after Withdrawal refactor.")
  static func parse(_ transactionStatus: TransactionStatus, isPendingHold: Bool, ignorePendingHold: Bool) -> String {
    switch transactionStatus {
    case .approved:
      return Localize.string("common_approved")
    case .cancel:
      return Localize.string("common_cancel")
    case .floating:
      return Localize.string("common_floating")
    case .reject,
         .void_:
      return Localize.string("common_reject")
    case .pending:
      if isPendingHold {
        return ignorePendingHold ? Localize.string("common_pending") : Localize.string("common_pending_hold")
      }
      else {
        return Localize.string("common_pending")
      }
    default:
      return ""
    }
  }

  static func parse(_ log: WithdrawalDto.Log) -> String {
    switch log.status {
    case .pending:
      return log.isPendingHold
        ? Localize.string("common_pending_hold")
        : Localize.string("common_pending")
    case .pendinghold:
      return Localize.string("common_pending")
    case .floating:
      return Localize.string("common_floating")
    case .approved:
      return Localize.string("common_approved")
    case .cancel:
      return Localize.string("common_cancel")
    case .fail:
      return Localize.string("common_reject")
    case .other:
      return ""
    default:
      return ""
    }
  }

  static func getVerifyStatus(status: PlayerBankCardVerifyStatus) -> (text: String, color: UIColor) {
    switch status {
    case .pending:
      return (Localize.string("withdrawal_bankcard_new"), UIColor.gray9B9B9B)
    case .verified:
      return (Localize.string("cps_account_status_verified"), UIColor.green6AB336)
    case .onhold:
      return (Localize.string("withdrawal_bankcard_locked"), UIColor.orangeFF8000)
    default:
      return ("", UIColor.gray9B9B9B)
    }
  }

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
    case .numbergame:
      return Localize.string("common_keno")
    case .p2p:
      return Localize.string("common_p2p")
    case .arcade:
      return Localize.string("common_arcade")
    case .none:
      return Localize.string("bonus_bonustype_3")
    default:
      return ""
    }
  }

  static func parseBonusTypeString(bonusType: BonusType) -> String {
    switch bonusType {
    case .rebate:
      return Localize.string("common_rebate")
    case .freebet:
      return Localize.string("common_freebet")
    case .depositbonus,
         .levelbonus:
      return Localize.string("common_depositbonus")
    case .product:
      return Localize.string("bonus_bonustype_3")
    case .vvipcashback:
      return Localize.string("bonus_bonustype_7")
    default:
      return ""
    }
  }

  static func parseprivilegeTypeTypeString(privilegeType: PrivilegeType) -> String {
    switch privilegeType {
    case .rebate:
      return Localize.string("common_rebate")
    case .freebet:
      return Localize.string("common_freebet")
    case .depositbonus,
         .levelbonus:
      return Localize.string("common_depositbonus")
    case .product:
      return Localize.string("bonus_bonustype_3")
    case .vvipcashback:
      return Localize.string("bonus_bonustype_7")
    default:
      return ""
    }
  }

  static func parse(bonusReceivingStatus: BonusReceivingStatus) -> String {
    switch bonusReceivingStatus {
    case .noturnover:
      return Localize.string("bonus_bonuslockstatus_0")
    case .inprogress:
      return Localize.string("bonus_bonuslockstatus_1")
    case .completed:
      return Localize.string("bonus_bonuslockstatus_2")
    case .canceled:
      return Localize.string("bonus_bonuslockstatus_3")
    default:
      return ""
    }
  }

  static func localizeBankName(banks tuple: [(Int, Bank)], supportLocale: SupportLocale) -> [String] {
    switch supportLocale {
    case is SupportLocale.Vietnam:
      return tuple.map { "(\($0.1.shortName)) \($0.1.name)" }
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      return tuple.map { $0.1.name }
    default:
      return []
    }
  }

  static func splitShortNameAndBankName(bankName: String, supportLocale: SupportLocale) -> String {
    switch supportLocale {
    case is SupportLocale.Vietnam:
      return bankName.components(separatedBy: ") ").last ?? bankName
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      return bankName
    }
  }
}
