import Foundation
import RxSwift
import SharedBu

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

  func createPromotionSecurityprivacy() -> Single<[TermsOfService]> {
    localizationPolicyUseCase.getServiceTerms().map { data in
      var arr = [TermsOfService]()
      arr.append(TermsOfService(title: data.title, content: data.contents, selected: false))
      data.terms.forEach {
        arr.append(TermsOfService(title: $0.title, content: $0.contents, selected: false))
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
      arr.append(TermsOfService(title: data.title, content: data.contents, selected: false))
      data.terms.forEach {
        arr.append(TermsOfService(title: $0.title, content: $0.contents, selected: false))
      }

      return arr
    }
  }

  func initLocale() -> Completable {
    localizationPolicyUseCase.initLocale()
  }
}
