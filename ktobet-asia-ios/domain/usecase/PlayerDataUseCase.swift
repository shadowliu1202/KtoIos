import Foundation
import RxSwift
import SharedBu

protocol PlayerDataUseCase {
    func getBalance() -> Single<AccountCurrency>
    func setBalanceHiddenState(gameId: String, isHidden: Bool)
    func getBalanceHiddenState(gameId: String) -> Bool
    func loadPlayer() -> Single<Player>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]>
    func isRealNameEditable() -> Single<Bool>
    func getPrivilege() -> Single<[LevelOverview]>
    func getSupportLocalFromCache() -> SupportLocale
    func getPlayerRealName() -> Single<String>
    func isAffiliateMember() -> Single<Bool>
    func checkProfileEditable() -> Single<Bool>
    func loadPlayerProfile() -> Single<PlayerProfile>
    func authorizeProfileEdition(password: String) -> Single<Bool>
    func changePassword(password: String) -> Completable
    func verifyOldAccount(_ accountType: AccountType) -> Completable
    func setWithdrawalName(name: String) -> Completable
    func getLocale() -> Locale
    func setBirthDay(birthDay: Date) -> Completable
    func verifyOldAccountOtp(_ otp: String, _ accountType: AccountType) -> Completable
    func resendOtp(_ accountType: AccountType) -> Completable
    func setEmail(_ email: String) -> Completable
    func verifyNewAccountOtp(_ otp: String, _ accountType: AccountType) -> Completable
    func setMobile(_ mobile: String) -> Completable
}

let PASSWORD_ERROR_LIMIT = 5
class PlayerDataUseCaseImpl: PlayerDataUseCase {
    var playerRepository : PlayerRepository!
    var localRepository: LocalStorageRepository!
    var settingStore: SettingStore!
    private var passwordErrorCount: Int = 0
    
    init(_ playerRepository : PlayerRepository, localRepository: LocalStorageRepository, settingStore: SettingStore) {
        self.playerRepository = playerRepository
        self.localRepository = localRepository
        self.settingStore = settingStore
    }
    
    func getBalance() -> Single<AccountCurrency> {
        return self.playerRepository.getBalance(localRepository.getSupportLocale())
    }
    
    func setBalanceHiddenState(gameId: String, isHidden: Bool) {
        localRepository.setBalanceHiddenState(isHidden: isHidden, gameId: gameId)
    }

    func getBalanceHiddenState(gameId: String) -> Bool {
        return localRepository.getBalanceHiddenState(gameId: gameId)
    }

    func loadPlayer() -> Single<Player> {
        playerRepository.loadPlayer()
    }
    
    func getPlayerRealName() -> Single<String> {
        playerRepository.getPlayerRealName()
    }
    
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<[String: Double]> {
        return playerRepository.getCashLogSummary(begin: begin, end: end, balanceLogFilterType: balanceLogFilterType)
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerRepository.isRealNameEditable()
    }
    
    func getPrivilege() -> Single<[LevelOverview]> {
        return playerRepository.getLevelPrivileges()
    }
    
    func getSupportLocalFromCache() -> SupportLocale {
        return localRepository.getSupportLocale()
    }
    
    func isAffiliateMember() -> Single<Bool> {
        return playerRepository.getAffiliateStatus().map({ $0 == AffiliateApplyStatus.applied })
    }
    
    func checkProfileEditable() -> Single<Bool> {
        return playerRepository.checkProfileAuthorization()
    }
    
    func loadPlayerProfile() -> Single<PlayerProfile> {
        return playerRepository.getPlayerProfile()
    }
    
    func authorizeProfileEdition(password: String) -> Single<Bool> {
        return playerRepository.verifyProfileAuthorization(password: password).andThen(checkProfileEditable())
            .do(onSuccess: { [unowned self] _ in
                self.passwordErrorCount = 0
            }, onError: { [unowned self] in
                if $0 is KtoPasswordVerifyFail {
                    self.passwordErrorCount += 1
                }
            }).catchError({ [unowned self] in
                return Single.error(self.handlePasswordVerify($0))
            })
    }
    
    func verifyOldAccount(_ accountType: AccountType) -> Completable {
        playerRepository.verifyOldAccount(accountType)
    }
    
    private func handlePasswordVerify(_ error: Error) -> Error {
        return error is KtoPasswordVerifyFail ? self.passwordErrorCount >= PASSWORD_ERROR_LIMIT ? KtoPasswordVerifyFailLimitExceed() : KtoPasswordVerifyFail() : error
    }
    
    func changePassword(password: String) -> Completable {
        return playerRepository.changePassword(password: password)
    }
    
    func setWithdrawalName(name: String) -> Completable {
        return playerRepository.setWithdrawalName(name: name)
    }
    
    func getLocale() -> Locale {
        return localRepository.getLocale()
    }
    
    func setBirthDay(birthDay: Date) -> Completable {
        return playerRepository.setBirthDay(birthDay: birthDay)
    }

    func verifyOldAccountOtp(_ otp: String, _ accountType: AccountType) -> Completable {
        playerRepository.verifyChangeIdentityOtp(otp, accountType, true)
    }
    
    func resendOtp(_ accountType: AccountType) -> Completable {
        playerRepository.resendOtp(accountType)
    }
    
    func setEmail(_ email: String) -> Completable {
        playerRepository.setIdentity(email, .email)
    }
    
    func setMobile(_ mobile: String) -> Completable {
        playerRepository.setIdentity(mobile, .phone)
    }
    
    func verifyNewAccountOtp(_ otp: String, _ accountType: AccountType) -> Completable {
        playerRepository.verifyChangeIdentityOtp(otp, accountType, false)
    }
}
