import Foundation
import RxSwift
import sharedbu

protocol LocalizationPolicyUseCase {
    func getPromotionPolicy() -> Single<PromotionPolicy>
    func initLocale() -> Completable
    func getCryptoGuidance() -> Single<[CryptoDepositGuidance]>
}

class LocalizationPolicyUseCaseImpl: LocalizationPolicyUseCase {
    private var repo: LocalizationRepository!

    init(_ repo: LocalizationRepository) {
        self.repo = repo
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

            return PromotionPolicy(
                title: data["License_Promotion_Terms"] ?? "",
                content: list,
                linkTitle: data["License_Promotion_PrivacyPolicy"] ?? "")
        }
    }

    func initLocale() -> Completable {
        repo.setupCultureCode()
    }

    func getCryptoGuidance() -> Single<[CryptoDepositGuidance]> {
        repo.getCryptoTutorials()
    }
}
