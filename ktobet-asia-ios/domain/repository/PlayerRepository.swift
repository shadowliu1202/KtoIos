import Foundation
import share_bu
import RxSwift

protocol PlayerRepository {
    func loadPlayer()-> Single<Player>
    func getDefaultProduct()->Single<ProductType>
    func saveDefaultProduct(_ productType: ProductType)->Completable
    func getBalance() -> Single<CashAmount>
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<[String: Double]>
}

class PlayerRepositoryImpl : PlayerRepository {
    
    private var playerApi : PlayerApi!
    private var portalApi : PortalApi!
    
    init(_ playerApi : PlayerApi, _ portalApi : PortalApi) {
        self.playerApi = playerApi
        self.portalApi = portalApi
    }
    
    func loadPlayer()-> Single<Player>{
        
        let favorProduct = getDefaultProduct()
        let localization = portalApi.getLocalization()
        let playerInfo = playerApi.getPlayerInfo()
        
        return Single
            .zip(favorProduct, localization, playerInfo)
            .map { (defaultProduct, responseLocalization, responsePlayerInfo) -> Player in
                let bindLocale : SupportLocale = {
                    switch responseLocalization.data?.cultureCode{
                    case "zh-cn" :
                        Localize.setLanguage(language: .ZH)
                        return SupportLocale.China()
                    case "vi-vn" :
                        Localize.setLanguage(language: .VI)
                        return SupportLocale.Vietnam()
                    default: return SupportLocale.China()
                    }
                }()
                let playerInfo = PlayerInfo(gameId: responsePlayerInfo.data?.gameId ?? "",
                                            displayId: responsePlayerInfo.data?.displayId ?? "" ,
                                            realName: responsePlayerInfo.data?.realName ?? "" ,
                                            level: Int32(responsePlayerInfo.data?.level ?? 0 ),
                                            exp: responsePlayerInfo.data?.exp ?? 0 ,
                                            autoUseCoupon: responsePlayerInfo.data?.isAutoUseCoupon ?? false )
                let player = Player(gameId: responsePlayerInfo.data?.gameId ?? "" ,
                                    playerInfo: playerInfo,
                                    bindLocale: bindLocale,
                                    defaultProduct: defaultProduct)
                return player
            }
    }
    
    func getDefaultProduct()->Single<ProductType>{
        return playerApi.getFavoriteProduct().map { (type) -> ProductType in
            switch type{
            case 0: return ProductType.none
            case 1: return ProductType.slot
            case 2: return ProductType.casino
            case 3: return ProductType.sbk
            case 4: return ProductType.numbergame
            default: return ProductType.none
            }
        }
    }
    
    func saveDefaultProduct(_ productType: ProductType)->Completable{
        return playerApi.setFavoriteProduct(productId: Int(productType.ordinal))
    }
    
    func getBalance() -> Single<CashAmount> {
        return playerApi.getCashBalance().map { CashAmount(amount: Double($0.data ?? 0) )}
    }
    
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<[String: Double]> {
        return playerApi.getCashLogSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType).map { (response) -> [String: Double] in
            return response.data ?? [:]
        }
    }
}
