import Foundation
import RxSwift
import sharedbu

class TermsViewModel {
    private var localizationPolicyUseCase: LocalizationPolicyUseCase!
    private var systemStatusUseCase: ISystemStatusUseCase
    lazy var cryptoGuidance = localizationPolicyUseCase.getCryptoGuidance()
    lazy var yearOfCopyRight = systemStatusUseCase.fetchCopyRight()
    lazy var getCustomerServiceEmail = systemStatusUseCase.fetchCustomerServiceEmail()

    init(localizationPolicyUseCase: LocalizationPolicyUseCase, systemStatusUseCase: ISystemStatusUseCase) {
        self.localizationPolicyUseCase = localizationPolicyUseCase
        self.systemStatusUseCase = systemStatusUseCase
    }

    func getPromotionPolicy() -> Single<PromotionPolicy> {
        localizationPolicyUseCase.getPromotionPolicy()
    }

    func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
}
