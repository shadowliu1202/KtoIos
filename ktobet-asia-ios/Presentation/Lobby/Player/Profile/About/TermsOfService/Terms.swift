import Foundation
import SwiftUI

protocol Terms {
    var title: LocalizedStringKey { get }
    var description: LocalizedStringKey { get }
    var terms: [TermItem] { get }
}

struct TermItem {
    var title: LocalizedStringKey
    var content: LocalizedStringKey

    init(_ title: LocalizedStringKey, _ content: LocalizedStringKey) {
        self.title = title
        self.content = content
    }
}

class ServiceTerms: Terms {
    var title: LocalizedStringKey = "common_service_terms"
    var description: LocalizedStringKey = "license_warning"

    var terms: [TermItem] = [
        .init("license_definition", "license_definition_content"),
        .init("license_agree", "license_agree_content"),
        .init("license_modify", "license_modify_content"),
        .init("license_gaminginfo_intellectualproperty", "license_gaminginfo_intellectualproperty_content"),
        .init("license_condition", "license_condition_content"),
        .init("license_register_membership", "license_register_membership_content"),
        .init("license_bet_acceptbet", "license_bet_acceptbet_content"),
        .init("license_gamingsoftware_usagerights", "license_gamingsoftware_usagerights_content"),
        .init("license_transaction_settlement", "license_transaction_settlement_content"),
        .init("license_bouns", "license_bouns_content"),
        .init("license_promotion_reward", "license_promotion_reward_content"),
        .init("license_compensation", "license_compensation_content"),
        .init("license_disclaimer_specialconsideration", "license_disclaimer_specialconsideration_content"),
        .init("license_termination", "license_termination_content"),
        .init("license_linktoexternal", "license_linktoexternal_content"),
        .init("license_linktobettingsite", "license_linktobettingsite_content"),
        .init("license_addorbreak_gamblingcategories", "license_addorbreak_gamblingcategories_content"),
        .init("license_violation", "license_violation_content"),
        .init("license_priority_order", "license_priority_order_content"),
        .init("license_forcemajeure", "license_forcemajeure_content"),
        .init("license_abstain", "license_abstain_content"),
        .init("license_severability", "license_severability_content"),
        .init("license_law_jurisdiction", "license_law_jurisdiction_content"),
    ]
}

class SecurityPrivacyTerms: Terms {
    var title: LocalizedStringKey = "common_privacy_terms"
    var description: LocalizedStringKey = "license_privacy_warning"

    var terms: [TermItem] = [
        .init("license_privacy_messagecollect_use", "license_privacy_definition_content"),
        .init("license_privacy_transaction", "license_privacy_transaction_content"),
        .init("license_privacy_promotion_information", "license_privacy_promotion_information_content"),
        .init("license_privacy_playerinformation", "license_privacy_playerinformation_content"),
        .init("license_privacy_playerinformationsafe", "license_privacy_playerinformationsafe_content"),
        .init("license_privacy_phone", "license_privacy_phone_content"),
        .init("license_privacy_docfile", "license_privacy_docfile_content"),
        .init("license_privacy_webmessage", "license_privacy_webmessage_content"),
        .init("license_privacy_advertisement", "license_privacy_advertisement_content"),
        .init("license_privacy_bonus", "license_privacy_bonus_content"),
        .init("license_privacy_safety", "license_privacy_safety_content"),
    ]
}

class GameblingResponsibility: Terms {
    var title: LocalizedStringKey = "license_responsibilitygambling_title"
    var description: LocalizedStringKey = "license_responsibilitygambling_content"

    var terms: [TermItem] = [
        .init("license_responsibilitygambling_age_limit_title", "license_responsibilitygambling_age_limit_content"),
        .init("license_gamblingprotection_title", "license_gamblingprotection_content"),
    ]
}
