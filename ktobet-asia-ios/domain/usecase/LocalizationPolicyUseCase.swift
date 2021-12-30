import Foundation
import SharedBu
import RxSwift

protocol LocalizationPolicyUseCase {
    func getServiceTerms() -> Single<TermsDetail>
    func getPromotionPolicy() -> Single<PromotionPolicy>
    func getPrivacyTerms() -> Single<TermsDetail>
    func initLocale() -> Completable
    func getCryptoGuidance() -> Single<[CryptoDepositGuidance]>
}

class LocalizationPolicyUseCaseImpl: LocalizationPolicyUseCase {
    private var repo: LocalizationRepository!
    
    init(_ repo: LocalizationRepository) {
        self.repo = repo
    }
    
    func getServiceTerms() -> Single<TermsDetail> {
        repo.getLocalization().map { data in
            TermsDetail(title: data["License_Terms_Service"] ?? "",
                        contents: data["License_Warning"] ?? "",
                        terms: [
                            self.createTerms(data, titleKey: "License_Definition", contentKey: "License_Definition_Content"),
                            self.createTerms(data, titleKey: "License_Agree", contentKey: "License_Agree_Content"),
                            self.createTerms(data, titleKey: "License_Modify", contentKey: "License_Modify_Content"),
                            self.createTerms(data, titleKey: "License_GamingInfo_IntellectualProperty", contentKey: "License_GamingInfo_IntellectualProperty_Content"),
                            self.createTerms(data, titleKey: "License_Condition", contentKey: "License_Condition_Content"),
                            self.createTerms(data, titleKey: "License_Register_Membership", contentKey: "License_Register_Membership_Content"),
                            self.createTerms(data, titleKey: "License_Bet_AcceptBet", contentKey: "License_Bet_AcceptBet_Content"),
                            self.createTerms(data, titleKey: "License_GamingSoftware_UsageRights", contentKey: "License_GamingSoftware_UsageRights_Content"),
                            self.createTerms(data, titleKey: "License_Transaction_Settlement", contentKey: "License_Transaction_Settlement_Content"),
                            self.createTerms(data, titleKey: "License_Bouns", contentKey: "License_Bouns_Content"),
                            self.createTerms(data, titleKey: "License_Promotion_Reward", contentKey: "License_Promotion_Reward_Content"),
                            self.createTerms(data, titleKey: "License_Compensation", contentKey: "License_Compensation_Content"),
                            self.createTerms(data, titleKey: "License_Disclaimer_SpecialConsideration", contentKey: "License_Disclaimer_SpecialConsideration_Content"),
                            self.createTerms(data, titleKey: "License_Termination", contentKey: "License_Termination_Content"),
                            self.createTerms(data, titleKey: "License_LinkToExternal", contentKey: "License_LinkToExternal_Content"),
                            self.createTerms(data, titleKey: "License_LinkToBettingSite", contentKey: "License_LinkToBettingSite_Content"),
                            self.createTerms(data, titleKey: "License_AddOrBreak_GamblingCategories", contentKey: "License_AddOrBreak_GamblingCategories_Content"),
                            self.createTerms(data, titleKey: "License_Violation", contentKey: "License_Violation_Content"),
                            self.createTerms(data, titleKey: "License_Priority_Order", contentKey: "License_Priority_Order_Content"),
                            self.createTerms(data, titleKey: "License_ForceMajeure", contentKey: "License_ForceMajeure_Content"),
                            self.createTerms(data, titleKey: "License_Abstain", contentKey: "License_Abstain_Content"),
                            self.createTerms(data, titleKey: "License_Severability", contentKey: "License_Severability_Content"),
                            self.createTerms(data, titleKey: "License_Law_Jurisdiction", contentKey: "License_Law_Jurisdiction_Content")
                        ])
        }
    }
    
    func getPromotionPolicy() -> Single<PromotionPolicy> {
        repo.getLocalization().map { data in
            let list = data.filter { element in
                element.key.contains("License_Promotion_Warning")
            }.map { ($0.key, $0.value) }
                .sorted { t1, t2 in
                let no1 = Int(t1.0.replacingOccurrences(of: "License_Promotion_Warning_", with: "")) ?? 0
                let no2 = Int(t2.0.replacingOccurrences(of: "License_Promotion_Warning_", with: "")) ?? 0
                return no1 < no2
            }.map { $0.1 }

            return PromotionPolicy(title: data["License_Promotion_Terms"] ?? "",
                                   content: list,
                                   linkTitle: data["License_Promotion_PrivacyPolicy"] ?? "")
        }
    }
    
    func getPrivacyTerms() -> Single<TermsDetail> {
        repo.getLocalization().map { data in
            TermsDetail(title: data["License_Privacy_Responsibility"] ?? "",
                        contents: [data["License_Privacy_Warning_1"] ?? "",
                                   data["License_Privacy_Warning_2"] ?? "",
                                   data["License_Privacy_Warning_3"] ?? ""].joined(separator: "\n"),
                        terms: [
                            self.createTerms(data, titleKey: "License_Privacy_MessageCollect_Use", contentKey: "License_Privacy_Definition_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Transaction", contentKey: "License_Privacy_Transaction_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Promotion_Information", contentKey: "License_Privacy_Promotion_Information_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_PlayerInformation", contentKey: "License_Privacy_PlayerInformation_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_PlayerInformationSafe", contentKey: "License_Privacy_PlayerInformationSafe_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Phone", contentKey: "License_Privacy_Phone_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_DocFile", contentKey: "License_Privacy_DocFile_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_WebMessage", contentKey: "License_Privacy_WebMessage_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Advertisement", contentKey: "License_Privacy_Advertisement_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Bonus", contentKey: "License_Privacy_Bonus_Content"),
                            self.createTerms(data, titleKey: "License_Privacy_Safety", contentKey: "License_Privacy_Safety_Content")
                        ])
        }
    }
    
    func initLocale() -> Completable {
        repo.setupCultureCode()
    }
    
    private func createTerms(_ map: [String: String], titleKey: String, contentKey: String) -> Term {
        Term(title: map[titleKey] ?? "", contents: map[contentKey] ?? "")
    }
    
    func getCryptoGuidance() -> Single<[CryptoDepositGuidance]> {
        repo.getCryptoTutorials()
    }

    
    /*
    func getCryptoGuidance() -> Single<CryptoGuidance> {
        let str =
"""
{
  "title": "新虚拟币用户指南",
  "description": "以下是新用户可以购买虚拟币的交易所列表。我们尽量保持信息更新，但我们不对客户在各交易所探索过程中出现的不准确信息或任何损失负责。如果对交易所使用有任何疑问或问题，建议您直接联交易所客服。",
  "cryptoType": [
    {
      "name": "币安",
      "content": [
        {
          "item": "新手必读",
          "link": "https://www.okex.com/support/hc/zh-cn/sections/360000033031-%E6%96%B0%E6%89%8B%E5%BF%85%E8%AF%BB"
        },
        {
          "item": "下载",
          "link": "https://www.okex.com/support/hc/zh-cn/articles/115003835372-%E4%B8%8B%E8%BD%BD%E6%AC%A7%E6%98%93OKEx%E6%8A%A2%E9%B2%9C%E7%89%88%E6%89%8B%E6%9C%BAApp"
        },
        {
          "item": "注册",
          "link": "https://www.okex.com/support/hc/zh-cn/articles/360055591692-6-%E6%B3%A8%E5%86%8C%E8%B4%A6%E6%88%B7%E6%93%8D%E4%BD%9C%E6%8C%87%E5%8D%97-APP%E7%AB%AF-"
        }
      ]
    },
    {
      "name": "芝麻开门",
      "content": [
        {
          "item": "买卖币",
          "link": "https://www.gate.tv/help/c2c/trade/17252/%E4%B8%80%E9%94%AE%E4%B9%B0%E5%B8%81%E6%93%8D%E4%BD%9C%E8%AF%B4%E6%98%8E-app%E7%89%88"
        },
        {
          "item": "提币",
          "link": "https://www.gate.io/help/guide/deposit_withdrawa/16447/how-to-withdraw-funds"
        },
        {
          "item": "手续费",
          "link": "https://www.gate.io/help/c2c/instructions/22244/how-much-does-gate.io-charge-for-p2p-tradings"
        }
      ]
    }
  ]
}
"""
        if let decoded = try? JSONDecoder().decode(CryptoGuidance.self, from: Data(str.utf8)) {
            return Single.just(decoded)
        } else {
            print("Not working")
            return Single.never()
        }
    }
     */
}
