import Foundation
import RxSwift
import sharedbu

protocol PlayerRepository {
  func loadPlayer() -> Single<Player>
  func fetchPlayerInfo() -> Single<PlayerBean>
  func getUtcOffset() -> Single<UtcOffset>
  func getDefaultProduct() -> Single<ProductType>
  func saveDefaultProduct(_ productType: ProductType) -> Completable
  func getBalance(_ supportLocale: SupportLocale) -> Single<AccountCurrency>
  func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]>
  func isRealNameEditable() -> Single<Bool>
  func getLevelPrivileges() -> Single<[LevelOverview]>
  func getPlayerRealName() -> Single<String>
  func hasPlayerData() -> Single<Bool>
  func getAffiliateStatus() -> Single<AffiliateApplyStatus>
  func getAffiliateHashKey() -> Single<String>
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

class PlayerRepositoryImpl: PlayerRepository {
  private let httpClient: HttpClient
  private var playerApi: PlayerApi!
  private var portalApi: PortalApi!
  private var settingStore: SettingStore!
  private let localStorageRepo: LocalStorageRepository
  private let memoryRepo: MemoryCacheImpl
  private let defaultProductProtocol: DefaultProductProtocol

  init(
    _ httpClient: HttpClient,
    _ playerApi: PlayerApi,
    _ portalApi: PortalApi,
    _ settingStore: SettingStore,
    _ localStorageRepo: LocalStorageRepository,
    _ memoryRepo: MemoryCacheImpl,
    _ defaultProductProtocol: DefaultProductProtocol)
  {
    self.httpClient = httpClient
    self.playerApi = playerApi
    self.portalApi = portalApi
    self.settingStore = settingStore
    self.localStorageRepo = localStorageRepo
    self.memoryRepo = memoryRepo
    self.defaultProductProtocol = defaultProductProtocol
  }

  func loadPlayer() -> Single<Player> {
    let favorProduct = getDefaultProduct().do(onSubscribe: { Logger.shared.info("GetFavoriteProduct_onSubscribe") })
    let localization = playerApi.getCultureCode().do(onSubscribe: { Logger.shared.info("GetCultureCode_onSubscribe") })
    let contactInfo = playerApi.getPlayerContact().do(onSubscribe: { Logger.shared.info("GetContactInfo_onSubscribe") })
    let playerInfo = playerApi.getPlayerInfo()
      .do(
        onSuccess: { [weak self] in
          if let data = $0.data {
            self?.settingStore.playerInfo = data
            AnalyticsManager.setUserID(data.gameId)
          }
        },
        onSubscribe: { Logger.shared.info("GetPlayerInfo_onSubscribe") })
    
    return Single
      .zip(favorProduct, localization, playerInfo, contactInfo)
      .map { defaultProduct, responseLocalization, responsePlayerInfo, responseContactInfo -> Player in
        let playerLocale = SupportLocale.Companion().create(language: responseLocalization.data)

        let playerInfo = PlayerInfo(
          gameId: responsePlayerInfo.data?.gameId ?? "",
          displayId: responsePlayerInfo.data?.displayId ?? "",
          withdrawalName: responsePlayerInfo.data?.realName ?? "",
          level: Int32(responsePlayerInfo.data?.level ?? 0),
          exp: Percentage(percent: (responsePlayerInfo.data?.exp) ?? 0),
          autoUseCoupon: responsePlayerInfo.data?.isAutoUseCoupon ?? false,
          contact: PlayerInfo.Contact(
            email: responseContactInfo.data?.email,
            mobile: responseContactInfo.data?.mobile))
        
        return Player(
          gameId: responsePlayerInfo.data?.gameId ?? "",
          playerInfo: playerInfo,
          bindLocale: playerLocale,
          defaultProduct: defaultProduct)
      }
      .do(onSuccess: { [localStorageRepo] player in
        localStorageRepo.setUserName(player.playerInfo.withdrawalName)
        localStorageRepo.setPlayerInfo(player)
        localStorageRepo.setLastAPISuccessDate(Date())
      })
  }
  
  func fetchPlayerInfo() -> Single<PlayerBean> {
    playerApi.getPlayerInfo()
      .flatMap {
        guard let playerBean = $0.data
        else { return .error(KTOError.EmptyData) }
        
        return .just(playerBean)
      }
      .do(onSuccess: { [localStorageRepo] in
        localStorageRepo.updatePlayerInfoCache(level: Int32($0.level))
      })
  }

  func getUtcOffset() -> Single<UtcOffset> {
    if let offset = memoryRepo.get(KeyPlayer).map({ (player: Player) in player.zoneOffset() }) {
      return Single<UtcOffset>.just(offset)
    }
    else {
      return self.loadPlayer().do(onSuccess: { [weak self] in self?.memoryRepo.set(KeyPlayer, $0) }).map { $0.zoneOffset() }
    }
  }

  func getDefaultProduct() -> Single<ProductType> {
    Single.from(defaultProductProtocol.getFavoriteProduct())
      .map { $0.data?.int32Value }
      .map { [weak self] in
        guard let self else { return .none }
        
        self.settingStore.defaultProduct = $0
        return self.convertDefaultProduct(type: $0)
      }
  }
  
  @available(*, deprecated, message: "will remove after move player profile to sharebu")
  private func convertDefaultProduct(type: Int32?) -> ProductType {
    switch type {
    case 1: return ProductType.slot
    case 2: return ProductType.casino
    case 3: return ProductType.sbk
    case 4: return ProductType.numberGame
    default: return .none
    }
  }

  func saveDefaultProduct(_ productType: ProductType) -> Completable {
    Completable.from(defaultProductProtocol.setFavoriteProduct(productId: productType.ordinal))
      .do(onCompleted: { [weak self] in
        self?.settingStore?.defaultProduct = productType.ordinal
      })
  }

  func getBalance(_ supportLocale: SupportLocale) -> Single<AccountCurrency> {
    playerApi.getCashBalance().map {
      FiatFactory().create(supportLocale: supportLocale, amount: "\(Double($0.data ?? 0))")
    }
  }

  func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]> {
    playerApi.getCashLogSummary(
      begin: begin.toDateStartTimeString(with: "-"),
      end: end.toDateStartTimeString(with: "-"),
      balanceLogFilterType: balanceLogFilterType).map { response -> [String: Double] in
      response.data ?? [:]
    }
  }

  func getPlayerRealName() -> Single<String> {
    playerApi.getPlayerRealName().map { $0.data ?? "" }
  }

  func isRealNameEditable() -> Single<Bool> {
    playerApi.isRealNameEditable().map { $0.data ?? false }
  }

  func getLevelPrivileges() -> Single<[LevelOverview]> {
    playerApi.getPlayerLevel().map { response -> [LevelOverview] in
      guard let data = response.data else { return [] }
      return try data.map { try self.convert(levelBean: $0) }
    }
  }

  func hasPlayerData() -> Single<Bool> {
    Single<Bool>.create { [weak self] single in
      guard let self else { single(.success(false))
        return Disposables.create()
      }
      if
        self.settingStore.defaultProduct != nil, let playerInfo = self.settingStore.playerInfo,
        !playerInfo.gameId.isEmpty
      {
        single(.success(true))
      }
      else {
        single(.success(false))
      }
      return Disposables.create()
    }
  }

  func verifyOldAccount(_ verifyType: AccountType) -> Completable {
    playerApi.sendOldAccountOtp(accountType: verifyType.rawValue).asCompletable()
  }

  private func convert(levelBean: LevelBean) throws -> LevelOverview {
    let privileges = levelBean.data?.map { self.convert(level: levelBean.level, privilegeBean: $0) } ?? []
    return try LevelOverview(
      level: levelBean.level,
      timeStamp: levelBean.timestamp.toKotlinLocalDateTime(),
      privileges: privileges)
  }

  private func convert(level: Int32, privilegeBean: PrivilegeBean) -> LevelPrivilege {
    PrivilegeFactory(stringSupporter: Localize, resourceMapper: LevelPrivilegeResourceMapper())
      .create(
        level: level,
        type: PrivilegeType.convert(privilegeBean.type),
        productType: ProductType.convert(privilegeBean.productType),
        betMultiple: privilegeBean.betMultiple,
        issueFrequency: LevelPrivilege.DepositIssueFrequencyCompanion().convert(type: privilegeBean.issueFrequency),
        maxBonus: privilegeBean.maxBonus.toAccountCurrency(),
        minCapital: privilegeBean.minCapital.toAccountCurrency(),
        percentage: Percentage(percent: privilegeBean.percentage),
        rebatePercentages: rebatePercentages(privilegeBean),
        withdrawalLimitAmount: privilegeBean.withdrawalLimitAmount.toAccountCurrency(),
        withdrawalLimitCount: privilegeBean.withdrawalLimitCount)
  }

  private func rebatePercentages(_ bean: PrivilegeBean) -> [ProductType: Percentage] {
    [
      ProductType.casino: Percentage(percent: bean.casinoPercentage),
      ProductType.numberGame: Percentage(percent: bean.numberGamePercentage),
      ProductType.sbk: Percentage(percent: bean.sbkPercentage),
      ProductType.slot: Percentage(percent: bean.slotPercentage),
      ProductType.arcade: Percentage(percent: bean.arcadePercentage)
    ]
  }

  func getAffiliateStatus() -> Single<AffiliateApplyStatus> {
    playerApi.getPlayerAffiliateStatus().map({ AffiliateApplyStatus.companion.create(type: $0.data) })
  }

  func getAffiliateHashKey() -> Single<String> {
    playerApi.getAffiliateHashKey().map { $0.data }
  }

  func checkProfileAuthorization() -> Single<Bool> {
    playerApi.checkProfileToken().map { $0.data }
  }

  func getPlayerProfile() -> Single<PlayerProfile> {
    playerApi.getPlayerProfile().map { result in
      if let data = result.data {
        return PlayerProfile(data)
      }
      return PlayerProfile()
    }
  }

  func verifyProfileAuthorization(password: String) -> Completable {
    playerApi.verifyPassword(RequestVerifyPassword(password: password)).catchException(transferLogic: {
      if $0 is PlayerPasswordFail {
        return KtoPasswordVerifyFail()
      }
      return $0
    }).asCompletable()
  }

  func changePassword(password: String) -> Completable {
    playerApi.resetPassword(RequestResetPassword(password: password)).catchException(transferLogic: {
      if $0 is PlayerPasswordRepeat {
        return KtoPasswordRepeat()
      }
      return $0
    }).asCompletable()
  }

  func setWithdrawalName(name: String) -> Completable {
    playerApi.setRealName(RequestSetRealName(realName: name)).catchException(transferLogic: {
      if $0 is PlayerProfileRealNameChangeForbidden {
        return KtoRealNameEditForbidden()
      }
      return $0
    }).asCompletable()
  }

  func setBirthDay(birthDay: Date) -> Completable {
    playerApi.setBirthDay(RequestChangeBirthDay(birthday: birthDay.toDateString()))
  }

  func verifyChangeIdentityOtp(_ otp: String, _ accountType: AccountType, _ isOldProfile: Bool) -> Completable {
    playerApi
      .verifyChangeIdentityOtp(RequestVerifyOtp(
        verifyCode: otp,
        bindProfileType: accountType.rawValue,
        isOldProfile: isOldProfile)).asCompletable()
  }

  func resendOtp(_ verifyType: AccountType) -> Completable {
    playerApi.resendOtp(verifyType.rawValue).asCompletable()
  }

  func setIdentity(_ identity: String, _ accountType: AccountType) -> Completable {
    playerApi.bindIdentity(request: RequestChangeIdentity(account: identity, bindProfileType: accountType.rawValue))
      .catchException(transferLogic: {
        switch $0 {
        case is PlayerOtpMailInactive,
             is PlayerOtpSmsInactive:
          return KtoOtpMaintenance()
        case is PlayerProfileAlreadyExist,
             is PlayerProfileInvalidInput,
             is PlayerProfileValidateFail:
          let exception = $0 as! ApiException
          return UnhandledException(message: exception.message, errorCode: exception.errorCode)
        case is PlayerProfileOldAccountVerifyFail:
          return KtoOldProfileValidateFail()
        case is PlayerIdOverOtpLimit,
             is PlayerIpOverOtpDailyLimit,
             is PlayerResentOtpLessResendTime,
             is PlayerResentOtpOverTenTimes: return KtoPlayerOverOtpDailySendLimit()
        default:
          return $0
        }
      }).asCompletable()
  }
}

class EditableContent<T> {
  var editable = true
  var content: T
  init(_ editable: Bool, _ content: T) {
    self.editable = editable
    self.content = content
  }
}

enum Gender: Int {
  case female
  case male
  case none
}

class PlayerProfile {
  var gameId = ""
  var loginId: EditableContent<String?> = EditableContent(false, nil)
  var gender: Gender = .none
  var birthDay: EditableContent<String?> = EditableContent(false, nil)
  var mobile: EditableContent<String?> = EditableContent(false, nil)
  var email: EditableContent<String?> = EditableContent(false, nil)
  var realName: EditableContent<String?> = EditableContent(false, nil)
  init() { }
  init(_ data: ProfileBean) {
    self.gameId = data.gameLoginId
    self.loginId = EditableContent(data.editable.loginId, data.loginId)
    if let gender = Gender(rawValue: data.gender) {
      self.gender = gender
    }
    let birthDayString = convertDate(data.birthday)?.toDateString()
    self.birthDay = EditableContent(data.editable.birthday, data.birthday != nil ? birthDayString : nil)
    self.mobile = EditableContent(data.editable.mobile, data.mobile)
    self.email = EditableContent(data.editable.email, data.email)
    self.realName = EditableContent(data.editable.realName, data.realName)
  }

  private func convertDate(_ dateStr: String?) -> Date? {
    guard let dateStr else {
      return nil
    }
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    dateFormatter.timeZone = Foundation.TimeZone(abbreviation: "UTC")
    return dateFormatter.date(from: dateStr)
  }
}
