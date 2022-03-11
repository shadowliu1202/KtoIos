import Foundation

protocol TermsPresenter {
    var navigationTitle: String { get }
    var barItemType: BarItemType { get }
    var description: String { get }
    var dataSourceTerms: [TermsOfService] { get }
}

struct TermsOfService {
    var title = ""
    var content = ""
    var selected = false
    
    init(title: String, content: String, selected: Bool) {
        self.title = title
        self.content = content
        self.selected = selected
    }
    
    init(_ title: String, _ content: String) {
        self.init(title: title, content: content, selected: false)
    }
}

class ServiceTerms: TermsPresenter {
    private var _barItemType: BarItemType
    var navigationTitle = Localize.string("common_service_terms")
    var barItemType: BarItemType { _barItemType }
    var description = Localize.string("license_warning")
    var dataSourceTerms: [TermsOfService]
    
    init(barItemType: BarItemType) {
        self._barItemType = barItemType
        self.dataSourceTerms = [TermsOfService(Localize.string("license_definition"), Localize.string("license_definition_content")),
                                TermsOfService(Localize.string("license_agree"), Localize.string("license_agree_content")),
                                TermsOfService(Localize.string("license_modify"), Localize.string("license_modify_content")),
                                TermsOfService(Localize.string("license_gaminginfo_intellectualproperty"), Localize.string("license_gaminginfo_intellectualproperty_content")),
                                TermsOfService(Localize.string("license_condition"), Localize.string("license_condition_content")),
                                TermsOfService(Localize.string("license_register_membership"), Localize.string("license_register_membership_content")),
                                TermsOfService(Localize.string("license_bet_acceptbet"), Localize.string("license_bet_acceptbet_content")),
                                TermsOfService(Localize.string("license_gamingsoftware_usagerights"), Localize.string("license_gamingsoftware_usagerights_content")),
                                TermsOfService(Localize.string("license_transaction_settlement"), Localize.string("license_transaction_settlement_content")),
                                TermsOfService(Localize.string("license_bouns"), Localize.string("license_bouns_content")),
                                TermsOfService(Localize.string("license_promotion_reward"), Localize.string("license_promotion_reward_content")),
                                TermsOfService(Localize.string("license_compensation"), Localize.string("license_compensation_content")),
                                TermsOfService(Localize.string("license_disclaimer_specialconsideration"), Localize.string("license_disclaimer_specialconsideration_content")),
                                TermsOfService(Localize.string("license_termination"), Localize.string("license_termination_content")),
                                TermsOfService(Localize.string("license_linktoexternal"), Localize.string("license_linktoexternal_content")),
                                TermsOfService(Localize.string("license_linktobettingsite"), Localize.string("license_linktobettingsite_content")),
                                TermsOfService(Localize.string("license_addorbreak_gamblingcategories"), Localize.string("license_addorbreak_gamblingcategories_content")),
                                TermsOfService(Localize.string("license_violation"), Localize.string("license_violation_content")),
                                TermsOfService(Localize.string("license_priority_order"), Localize.string("license_priority_order_content")),
                                TermsOfService(Localize.string("license_forcemajeure"), Localize.string("license_forcemajeure_content")),
                                TermsOfService(Localize.string("license_abstain"), Localize.string("license_abstain_content")),
                                TermsOfService(Localize.string("license_severability"), Localize.string("license_severability_content")),
                                TermsOfService(Localize.string("license_law_jurisdiction"), Localize.string("license_law_jurisdiction_content"))]
    }
}

class SecurityPrivacyTerms: TermsPresenter {
    var navigationTitle = Localize.string("common_privacy_terms")
    var barItemType: BarItemType = .back
    var description = Localize.string("license_privacy_warning")
    var dataSourceTerms: [TermsOfService]
    
    init() {
        dataSourceTerms = [TermsOfService(Localize.string("license_privacy_messagecollect_use"), Localize.string("license_privacy_definition_content")),
                           TermsOfService(Localize.string("license_privacy_transaction"), Localize.string("license_privacy_transaction_content")),
                           TermsOfService(Localize.string("license_privacy_promotion_information"), Localize.string("license_privacy_promotion_information_content")),
                           TermsOfService(Localize.string("license_privacy_playerinformation"), Localize.string("license_privacy_playerinformation_content")),
                           TermsOfService(Localize.string("license_privacy_playerinformationsafe"), Localize.string("license_privacy_playerinformationsafe_content")),
                           TermsOfService(Localize.string("license_privacy_phone"), Localize.string("license_privacy_phone_content")),
                           TermsOfService(Localize.string("license_privacy_docfile"), Localize.string("license_privacy_docfile_content")),
                           TermsOfService(Localize.string("license_privacy_webmessage"), Localize.string("license_privacy_webmessage_content")),
                           TermsOfService(Localize.string("license_privacy_advertisement"), Localize.string("license_privacy_advertisement_content")),
                           TermsOfService(Localize.string("license_privacy_bonus"), Localize.string("license_privacy_bonus_content")),
                           TermsOfService(Localize.string("license_privacy_safety"), Localize.string("license_privacy_safety_content"))]
    }
}

class GameblingResponsibility: TermsPresenter {
    var navigationTitle = Localize.string("license_responsibilitygambling_title")
    var barItemType: BarItemType = .back
    var description = Localize.string("license_responsibilitygambling_content")
    var dataSourceTerms: [TermsOfService]
    
    init() {
        dataSourceTerms = [
            TermsOfService(Localize.string("license_responsibilitygambling_age_limit_title"), Localize.string("license_responsibilitygambling_age_limit_content")),
            TermsOfService(Localize.string("license_gamblingprotection_title"), Localize.string("license_gamblingprotection_content"))]
    }
}
