import Foundation
import SharedBu
import RxSwift

protocol LocalizationRepository {
    func setupCultureCode() -> Completable
    func getLocalization() -> Single<[String: String]>
    func getCryptoTutorials() -> Single<[CryptoDepositGuidance]>
}

class LocalizationRepositoryImpl: LocalizationRepository {
    private let playerLocaleConfiguration: PlayerLocaleConfiguration
    private let portalApi: PortalApi
    
    init(_ playerLocaleConfiguration: PlayerLocaleConfiguration, _ portalApi: PortalApi) {
        self.playerLocaleConfiguration = playerLocaleConfiguration
        self.portalApi = portalApi
    }
    
    func setupCultureCode() -> Completable {
        portalApi.initLocale(cultureCode: playerLocaleConfiguration.getCultureCode())
    }
    
    func getLocalization() -> Single<[String : String]> {
        portalApi.getLocalization().flatMap { response in
            guard let data = response.data?.data else { return Single.error(KTOError.EmptyData) }
            return Single.just(data)
        }
    }
    
    func getCryptoTutorials() -> Single<[CryptoDepositGuidance]> {
        portalApi.getCryptoTutorials().flatMap { response in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single.just(data.map { bean in
                CryptoDepositGuidance(title: bean.name,
                                      links: bean.tutorials.map({ tutorialBean in
                    CryptoDepositGuidance.GuidanceLink(title: tutorialBean.name, link: tutorialBean.link)
                }))
            })
        }
    }

}
