import Foundation
import SharedBu
import UIKit

class StringMapper {
    static let sharedInstance = StringMapper()
    private init() { }
    
    private let localStorageRepo: PlayerLocaleConfiguration = DI.resolve(LocalStorageRepositoryImpl.self)!
    
    func parse(_ transactionStatus: TransactionStatus, isPendingHold: Bool, ignorePendingHold: Bool) -> String {
        switch transactionStatus {
        case .approved:
            return Localize.string("common_approved")
        case .cancel:
            return Localize.string("common_cancel")
        case .floating:
            return Localize.string("common_floating")
        case .void_, .reject:
            return Localize.string("common_reject")
        case .pending:
            if isPendingHold {
                return ignorePendingHold ? Localize.string("common_pending") : Localize.string("common_pending_hold")
            } else {
                return Localize.string("common_pending")
            }
        default:
            return ""
        }
    }
    
    func getVerifyStatus(status: PlayerBankCardVerifyStatus) -> (text: String, color: UIColor) {
        switch status {
        case .pending:
            return (Localize.string("withdrawal_bankcard_new"), UIColor.textPrimaryDustyGray)
        case .verified:
            return (Localize.string("cps_account_status_verified"), UIColor.textSuccessedGreen)
        default:
            return ("", UIColor.textPrimaryDustyGray)
        }
    }
    
    func getPromotionSortingTypeString(sortingType: SortingType) -> String {
        switch sortingType {
        case .asc:
            return Localize.string("bonus_orderby_asc")
        case .desc:
            return Localize.string("bonus_orderby_desc")
        }
    }
    
    func parseProductTypeString(productType: ProductType) -> String {
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
    
    func parseBonusTypeString(bonusType: BonusType) -> String {
        switch bonusType {
        case .rebate:
            return Localize.string("common_rebate")
        case .freebet:
            return Localize.string("common_freebet")
        case .depositbonus, .levelbonus:
            return Localize.string("common_depositbonus")
        case .product:
            return Localize.string("bonus_bonustype_3")
        default:
            return ""
        }
    }
    
    func parse(bonusReceivingStatus: BonusReceivingStatus) -> String {
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

    func localizeBankName(banks tuple: [(Int, Bank)]) -> [String] {
        switch localStorageRepo.getSupportLocale() {
        case is SupportLocale.Vietnam:
            return tuple.map{ "(\($0.1.shortName)) \($0.1.name)" }
        case is SupportLocale.China, is SupportLocale.Unknown:
            return tuple.map{ $0.1.name }
        default:
            return []
        }
    }
    
    func splitShortNameAndBankName(bankName: String) -> String {
        switch localStorageRepo.getSupportLocale() {
        case is SupportLocale.Vietnam:
            return bankName.components(separatedBy: ") ").last ?? bankName
        case is SupportLocale.China, is SupportLocale.Unknown:
            return bankName
        default:
            return bankName
        }
            
    }
}
