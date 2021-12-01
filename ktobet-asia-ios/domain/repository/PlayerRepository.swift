import Foundation
import SharedBu
import RxSwift

protocol PlayerRepository {
    func loadPlayer()-> Single<Player>
    func getDefaultProduct()->Single<ProductType>
    func saveDefaultProduct(_ productType: ProductType)->Completable
    func getBalance(_ supportLocale: SupportLocale) -> Single<AccountCurrency>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]>
    func isRealNameEditable() -> Single<Bool>
    func getLevelPrivileges() -> Single<[LevelOverview]>
    func getPlayerRealName() -> Single<String>
    func hasPlayerData() -> Single<Bool>
}

class PlayerRepositoryImpl : PlayerRepository {
    
    private var playerApi : PlayerApi!
    private var portalApi : PortalApi!
    private var settingStore: SettingStore!
    
    init(_ playerApi : PlayerApi, _ portalApi : PortalApi, _ settingStore: SettingStore) {
        self.playerApi = playerApi
        self.portalApi = portalApi
        self.settingStore = settingStore
    }
    
    func loadPlayer() -> Single<Player> {
        let favorProduct = getDefaultProduct()
        let localization = portalApi.getLocalization()
        let playerInfo = playerApi.getPlayerInfo().do(onSuccess: { [weak self] in
            if let data = $0.data {
                self?.settingStore.playerInfo = data
            }
        })
        let contactInfo = playerApi.getPlayerContact()
        
        return Single
            .zip(favorProduct, localization, playerInfo, contactInfo)
            .map { (defaultProduct, responseLocalization, responsePlayerInfo, responseContactInfo) -> Player in
                let bindLocale : SupportLocale = {
                    if let cultureCode = responseLocalization.data?.cultureCode {
                        return SupportLocale.Companion.init().create(language: cultureCode)
                    } else {
                        return SupportLocale.China()
                    }
                }()
                
                let playerInfo = PlayerInfo(gameId: responsePlayerInfo.data?.gameId ?? "",
                                            displayId: responsePlayerInfo.data?.displayId ?? "" ,
                                            withdrawalName: responsePlayerInfo.data?.realName ?? "" ,
                                            level: Int32(responsePlayerInfo.data?.level ?? 0 ),
                                            exp: Percentage(percent: (responsePlayerInfo.data?.exp) ?? 0),
                                            autoUseCoupon: responsePlayerInfo.data?.isAutoUseCoupon ?? false,
                                            contact: PlayerInfo.Contact.init(email: responseContactInfo.data?.email, mobile: responseContactInfo.data?.mobile) )
                let player = Player(gameId: responsePlayerInfo.data?.gameId ?? "" ,
                                    playerInfo: playerInfo,
                                    bindLocale: bindLocale,
                                    defaultProduct: defaultProduct)
                return player
            }
    }
    
    func getDefaultProduct()->Single<ProductType>{
        return playerApi.getFavoriteProduct().map { [weak self] (type) -> ProductType in
            self?.settingStore?.defaultProduct = Int32(type)
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
        return playerApi.setFavoriteProduct(productId: Int(productType.ordinal)).do(onCompleted: { [weak self] in
            self?.settingStore?.defaultProduct = productType.ordinal
        })
    }
    
    func getBalance(_ supportLocale: SupportLocale) -> Single<AccountCurrency> {
        return playerApi.getCashBalance().map {
            FiatFactory.init().create(supportLocale: supportLocale, amount_: "\(Double($0.data ?? 0))")
        }
    }
    
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]> {
        return playerApi.getCashLogSummary(begin: begin.toDateStartTimeString(with: "-"), end: end.toDateStartTimeString(with: "-"), balanceLogFilterType: balanceLogFilterType).map { (response) -> [String: Double] in
            return response.data ?? [:]
        }
    }
    
    func getPlayerRealName() -> Single<String> {
        playerApi.getPlayerRealName().map{ $0.data ?? "" }
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerApi.isRealNameEditable().map { $0.data ?? false }
    }
    
    func getLevelPrivileges() -> Single<[LevelOverview]> {
        playerApi.getPlayerLevel().map { (response) -> [LevelOverview] in
            guard let data = response.data else { return [] }
            return data.map{ self.convert(levelBean: $0) }
        }
    }
    
    func hasPlayerData() -> Single<Bool> {
        return Single<Bool>.create { [weak self] single in
            guard let `self` = self else { single(.success(false))
                return Disposables.create()
            }
            if self.settingStore.defaultProduct != nil, let playerInfo = self.settingStore.playerInfo, !playerInfo.gameId.isEmpty {
                single(.success(true))
            } else {
                single(.success(false))
            }
            return Disposables.create()
        }
    }
    
    private func convert(levelBean: LevelBean) -> LevelOverview {
        let timestamp = levelBean.timestamp.convertDateTime() ?? Date()
        let timestampLocalDateTime = Kotlinx_datetimeLocalDateTime(year: timestamp.getYear(), monthNumber: timestamp.getMonth(), dayOfMonth: timestamp.getDayOfMonth(), hour: timestamp.getHour(), minute: timestamp.getMinute(), second: timestamp.getSecond(), nanosecond: timestamp.getNanosecond())
        
        let privileges = levelBean.data?.map{ self.convert(level: levelBean.level, privilegeBean: $0) } ?? []
        return LevelOverview(level: levelBean.level, timeStamp: timestampLocalDateTime, privileges: privileges)
    }
    
    private func convert(level: Int32, privilegeBean: PrivilegeBean) -> LevelPrivilege {
        PrivilegeFactory.init(stringSupporter: Localize, resourceMapper: LevelPrivilegeResourceMapper())
            .create(level: level,
                    type: convertToPrivilegeType(type: privilegeBean.type),
                    productType: ProductType.convert(privilegeBean.productType),
                    betMultiple: privilegeBean.betMultiple,
                    issueFrequency: LevelPrivilege.DepositIssueFrequencyCompanion.init().convert(type: privilegeBean.issueFrequency),
                    maxBonus: privilegeBean.maxBonus.toAccountCurrency(),
                    minCapital: privilegeBean.minCapital.toAccountCurrency(),
                    percentage: Percentage(percent: privilegeBean.percentage),
                    rebatePercentages: rebatePercentages(privilegeBean),
                    withdrawalLimitAmount: privilegeBean.withdrawalLimitAmount.toAccountCurrency(),
                    withdrawalLimitCount: privilegeBean.withdrawalLimitCount)
    }
    
    private func convertToPrivilegeType(type: Int32) -> PrivilegeType {
        switch type {
        case 1:
            return PrivilegeType.freebet
        case 2:
            return PrivilegeType.depositbonus
        case 3:
            return PrivilegeType.product
        case 4:
            return PrivilegeType.rebate
        case 5:
            return PrivilegeType.levelbonus
        case 90:
            return PrivilegeType.feedback
        case 91:
            return PrivilegeType.withdrawal
        case 92:
            return PrivilegeType.domain
        default:
            return PrivilegeType.none
        }
    }
   
    private func rebatePercentages(_ bean: PrivilegeBean) -> [ProductType : Percentage] {
        [ProductType.casino: Percentage(percent: bean.casinoPercentage),
         ProductType.numbergame: Percentage(percent: bean.numberGamePercentage),
         ProductType.sbk: Percentage(percent: bean.sbkPercentage),
         ProductType.slot: Percentage(percent: bean.slotPercentage),
         ProductType.arcade: Percentage(percent: bean.arcadePercentage)]
    }
}
