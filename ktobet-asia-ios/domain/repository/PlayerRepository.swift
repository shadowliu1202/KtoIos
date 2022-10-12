import Foundation
import SharedBu
import RxSwift

protocol PlayerRepository {
    func refreshHttpClient(playerLocale: SupportLocale)
    func loadPlayer()-> Single<Player>
    func getUtcOffset() -> Single<UtcOffset>
    func getDefaultProduct()->Single<ProductType>
    func saveDefaultProduct(_ productType: ProductType)->Completable
    func getBalance(_ supportLocale: SupportLocale) -> Single<AccountCurrency>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]>
    func isRealNameEditable() -> Single<Bool>
    func getLevelPrivileges() -> Single<[LevelOverview]>
    func getPlayerRealName() -> Single<String>
    func hasPlayerData() -> Single<Bool>
    func getAffiliateStatus() -> Single<AffiliateApplyStatus>
    func checkProfileAuthorization() -> Single<Bool>
    func getPlayerProfile() -> Single<PlayerProfile>
    func verifyProfileAuthorization(password: String) -> Completable
    func changePassword(password: String) -> Completable
    func verifyOldAccount(_ verifyType: AccountType) -> Completable
    func setWithdrawalName(name: String) -> Completable
    func setBirthDay(birthDay: Date) -> Completable
    func verifyChangeIdentityOtp(_ otp: String, _ accountType: AccountType, _ isOldProfile: Bool) -> Completable
    func resendOtp(_ verifyType: AccountType) -> Completable
    func setIdentity(_ identity: String, _ accountType: AccountType) -> Completable
}

class PlayerRepositoryImpl : PlayerRepository {
    private let httpClient: HttpClient
    private var playerApi: PlayerApi!
    private var portalApi: PortalApi!
    private var settingStore: SettingStore!
    private let localStorageRepo: LocalStorageRepositoryImpl
    private let memoryRepo: MemoryCacheImpl
    
    init(_ httpClient: HttpClient,
         _ playerApi: PlayerApi,
         _ portalApi: PortalApi,
         _ settingStore: SettingStore,
         _ localStorageRepo: LocalStorageRepositoryImpl,
         _ memoryRepo: MemoryCacheImpl) {
        self.httpClient = httpClient
        self.playerApi = playerApi
        self.portalApi = portalApi
        self.settingStore = settingStore
        self.localStorageRepo = localStorageRepo
        self.memoryRepo = memoryRepo
    }
    
    func refreshHttpClient(playerLocale: SupportLocale) {
        let oldURLString = httpClient.host.description
        self.localStorageRepo.setCultureCode(playerLocale.cultureCode())
        Theme.shared.changeEntireAPPFont(by: playerLocale)
        DI.resetObjectScope(.locale)
        
        let newURLString = DI.resolve(HttpClient.self)!.host.description
        self.httpClient.replaceCookiesDomain(oldURLString, to: newURLString)
        DI.resetObjectScope(.locale)
    }
    
    func loadPlayer() -> Single<Player> {
        
        let favorProduct = getDefaultProduct()
        let localization = playerApi.getCultureCode()
        let playerInfo = playerApi.getPlayerInfo().do(onSuccess: { [weak self] in
            if let data = $0.data {
                self?.settingStore.playerInfo = data
                FirebaseLog.shared.setUserID(data.gameId)
            }
        })
        let contactInfo = playerApi.getPlayerContact()
        
        return Single
            .zip(favorProduct, localization, playerInfo, contactInfo)
            .map { (defaultProduct, responseLocalization, responsePlayerInfo, responseContactInfo) -> Player in
                let playerLocale : SupportLocale = {
                    if let cultureCode = responseLocalization.data {
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
                                    bindLocale: playerLocale,
                                    defaultProduct: defaultProduct)
                return player
            }
            .do(onSuccess: { self.localStorageRepo.setUserName($0.playerInfo.withdrawalName)})
    }
    
    func getUtcOffset() -> Single<UtcOffset> {
        if let offset = memoryRepo.get(KeyPlayer).map({ (player: Player) in player.zoneOffset() }) {
            return Single<UtcOffset>.just(offset)
        } else {
            return self.loadPlayer().do(onSuccess: { [weak self] in self?.memoryRepo.set(KeyPlayer, $0)}).map{ $0.zoneOffset() }
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
            return try data.map { try self.convert(levelBean: $0) }
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
    
    func verifyOldAccount(_ verifyType: AccountType) -> Completable {
        playerApi.sendOldAccountOtp(accountType: verifyType.rawValue).asCompletable()
    }
    
    private func convert(levelBean: LevelBean) throws -> LevelOverview {
        let privileges = levelBean.data?.map{ self.convert(level: levelBean.level, privilegeBean: $0) } ?? []
        return LevelOverview(level: levelBean.level, timeStamp: try levelBean.timestamp.toLocalDateTime(), privileges: privileges)
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
    
    func getAffiliateStatus() -> Single<AffiliateApplyStatus> {
        return playerApi.getPlayerAffiliateStatus().map({AffiliateApplyStatus.companion.create(type: $0.data)})
    }
    
    func checkProfileAuthorization() -> Single<Bool> {
        return playerApi.checkProfileToken().map { $0.data }
    }
    
    func getPlayerProfile() -> Single<PlayerProfile> {
        return playerApi.getPlayerProfile().map { result in
            if let data = result.data {
                return PlayerProfile(data)
            }
            return PlayerProfile()
        }
    }
    
    func verifyProfileAuthorization(password: String) -> Completable {
        return playerApi.verifyPassword(RequestVerifyPassword(password: password)).catchException(transferLogic: {
            if $0 is PlayerPasswordFail {
                return KtoPasswordVerifyFail()
            }
            return $0
        }).asCompletable()
    }
    
    func changePassword(password: String) -> Completable {
        return playerApi.resetPassword(RequestResetPassword(password: password)).catchException(transferLogic: {
            if $0 is PlayerPasswordRepeat {
                return KtoPasswordRepeat()
            }
            return $0
        }).asCompletable()
    }
    
    func setWithdrawalName(name: String) -> Completable {
        return playerApi.setRealName(RequestSetRealName(realName: name)).catchException(transferLogic: {
            if $0 is PlayerProfileRealNameChangeForbidden {
                return KtoRealNameEditForbidden()
            }
            return $0
        }).asCompletable()
    }
    
    func setBirthDay(birthDay: Date) -> Completable {
        return playerApi.setBirthDay(RequestChangeBirthDay(birthday: birthDay.toDateString()))
    }
    
    func verifyChangeIdentityOtp(_ otp: String, _ accountType: AccountType, _ isOldProfile: Bool) -> Completable {
        playerApi.verifyChangeIdentityOtp(RequestVerifyOtp(verifyCode: otp, bindProfileType: accountType.rawValue, isOldProfile: isOldProfile)).asCompletable()
    }
    
    func resendOtp(_ verifyType: AccountType) -> Completable {
        playerApi.resendOtp(verifyType.rawValue).asCompletable()
    }
    
    func setIdentity(_ identity: String, _ accountType: AccountType) -> Completable {
        playerApi.bindIdentity(request: RequestChangeIdentity(account: identity, bindProfileType: accountType.rawValue)).catchException(transferLogic: {
            switch $0 {
            case is PlayerOtpMailInactive, is PlayerOtpSmsInactive:
                return KtoOtpMaintenance()
            case is PlayerProfileInvalidInput, is PlayerProfileValidateFail, is PlayerProfileAlreadyExist:
                let exception = $0 as! ApiException
                return UnhandledException(message: exception.message, errorCode: exception.errorCode)
            case is PlayerProfileOldAccountVerifyFail:
                return KtoOldProfileValidateFail()
            case is PlayerIdOverOtpLimit, is PlayerIpOverOtpDailyLimit, is PlayerResentOtpOverTenTimes, is PlayerResentOtpLessResendTime:
                return KtoPlayerOverOtpDailySendLimit()
            default:
                return $0
            }
        }).asCompletable()
    }
}


class EditableContent<T> {
    var editable: Bool = true
    var content: T
    init(_ editable: Bool, _ content: T) {
        self.editable = editable
        self.content = content
    }
}

enum Gender: Int {
    case female, male, none
}

class PlayerProfile {
    var gameId: String = ""
    var loginId: EditableContent<String?> = EditableContent(false, nil)
    var gender: Gender = .none
    var birthDay: EditableContent<String?> = EditableContent(false, nil)
    var mobile: EditableContent<String?> = EditableContent(false, nil)
    var email: EditableContent<String?> = EditableContent(false, nil)
    var realName: EditableContent<String?> = EditableContent(false, nil)
    init() {}
    init(_ data: ProfileBean) {
        self.gameId = data.gameLoginId
        self.loginId = EditableContent(data.editable.loginId, data.loginId)
        if let gender = Gender.init(rawValue: data.gender) {
            self.gender = gender
        }
        let birthDayString = convertDate(data.birthday)?.toDateString()
        self.birthDay = EditableContent(data.editable.birthday, data.birthday != nil ?  birthDayString : nil)
        self.mobile = EditableContent(data.editable.mobile, data.mobile)
        self.email = EditableContent(data.editable.email, data.email)
        self.realName = EditableContent(data.editable.realName, data.realName)
    }
    
    private func convertDate(_ dateStr: String?) -> Date? {
        guard let dateStr = dateStr else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = Foundation.TimeZone(abbreviation: "UTC")
        return dateFormatter.date(from: dateStr)
    }
}
