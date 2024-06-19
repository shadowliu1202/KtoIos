import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import RxSwiftExt
import sharedbu

class OtpLoginViewModel: CollectErrorViewModel {
    private let systemUseCase: ISystemStatusUseCase
    private let playerConfiguration: PlayerConfiguration
    private let otpRepository: LoginByOtpRepository
    private let playerRepository: PlayerRepository

    private let disposeBag = DisposeBag()

    private let otpStatusRefreshSubject = PublishSubject<Void>()

    private var phoneEdited = false
    private var mailEdited = false
    private var passwordEdited = false

    var relayEmail = BehaviorRelay(value: "")
    var relayMobile = BehaviorRelay(value: "")
    var relayVerifyCode = BehaviorRelay(value: "")

    init(
        _ systemUseCase: ISystemStatusUseCase,
        _ playerConfiguration: PlayerConfiguration,
        _ otpRepository: LoginByOtpRepository,
        _ playerRepository: PlayerRepository
    ) {
        self.systemUseCase = systemUseCase
        self.playerConfiguration = playerConfiguration
        self.otpRepository = otpRepository
        self.playerRepository = playerRepository
    }

    func event() -> (
        otpStatus: Observable<OtpStatus>,
        emailValid: Observable<UserInfoStatus>,
        mobileValid: Observable<UserInfoStatus>
    ) {
        let emailValid = relayEmail
            .map { text -> UserInfoStatus in
                let valid = Account.Email(email: text).isValid()
                if text.count > 0 { self.mailEdited = true }
                if valid { return .valid }
                else if text.count == 0 {
                    if self.mailEdited { return .empty }
                    else { return .firstEmpty }
                } else { return .errEmailFormat }
            }

        let mobileValid = relayMobile
            .map { text -> UserInfoStatus in
                let valid = Account.Phone(phone: text, locale: self.playerConfiguration.supportLocale).isValid()
                if text.count > 0 { self.phoneEdited = true }
                if valid { return .valid }
                else if text.count == 0 {
                    if self.phoneEdited { return .empty }
                    else { return .firstEmpty }
                } else { return .errPhoneFormat }
            }

        let otpStatus = otpStatusRefreshSubject
            .flatMapLatest { [weak self] _ -> Single<OtpStatus?> in
                guard let self else {
                    return .just(nil)
                }
                return self.systemUseCase
                    .isOtpServiceAvaiable()
                    .map { $0 }
                    .catch { [weak self] error in
                        self?.errorsSubject.onNext(error)
                        return .just(nil)
                    }
            }
            .compactMap { $0 }
        return (
            otpStatus: otpStatus,
            emailValid: emailValid,
            mobileValid: mobileValid
        )
    }

    func refreshOtpStatus() {
        otpStatusRefreshSubject.onNext(())
    }

    func requestOtpLogin(_ selectedVerifyWay: AccountType) -> Completable {
        return otpRepository.login(identity: getAccount(selectedVerifyWay), accountType: selectedVerifyWay)
    }

    func getAccount(_ selectedVerifyWay: AccountType) -> String {
        selectedVerifyWay == .phone ? relayMobile.value : relayEmail.value
    }

    func resendOtp() -> Completable {
        otpRepository.resendOtp()
    }

    func loginByVerifyCode(by code: String) -> Completable {
        otpRepository.verifyOtp(by: code)
    }

    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }

    func getPlayerProfile() -> Single<Player> {
        playerRepository.loadPlayer()
    }
}
