import Foundation
import RxSwift
import SharedBu


class TermsViewModel {
    private var localizationPolicyUseCase : LocalizationPolicyUseCase!
    
    init(localizationPolicyUseCase: LocalizationPolicyUseCase) {
        self.localizationPolicyUseCase = localizationPolicyUseCase
    }
    
    func createPromotionSecurityprivacy() -> Single<[TermsOfService]> {
        localizationPolicyUseCase.getServiceTerms().map { data in
            var arr = [TermsOfService]()
            arr.append(TermsOfService.init(title: data.title, content: data.contents, selected: false))
            data.terms.forEach{
                arr.append(TermsOfService.init(title: $0.title, content: $0.contents, selected: false))
            }
            
            return arr
        }
    }
    
    func getPromotionPolicy() -> Single<PromotionPolicy> {
        localizationPolicyUseCase.getPromotionPolicy()
    }
    
    func getPrivacyTerms() -> Single<[TermsOfService]> {
        localizationPolicyUseCase.getPrivacyTerms().map { data in
            var arr = [TermsOfService]()
            arr.append(TermsOfService.init(title: data.title, content: data.contents, selected: false))
            data.terms.forEach{
                arr.append(TermsOfService.init(title: $0.title, content: $0.contents, selected: false))
            }
            
            return arr
        }
    }
    
    func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
}
