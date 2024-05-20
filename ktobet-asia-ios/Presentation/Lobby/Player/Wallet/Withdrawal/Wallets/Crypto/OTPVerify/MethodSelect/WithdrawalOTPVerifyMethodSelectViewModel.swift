import Combine
import RxCocoa
import RxSwift
import sharedbu

class WithdrawalOTPVerifyMethodSelectViewModel:
    WithdrawalOTPVerifyMethodSelectViewModelProtocol &
    ObservableObject &
    CollectErrorViewModel
{
    @Published private(set) var otpServiceAvailability: WithdrawalOTPVerifyMethodSelectDataModel
        .OTPServiceStatus = .unavailable("")
    @Published private(set) var isLoading = true
    @Published private(set) var isOTPRequestInProgress = false

    @Published var selectedAccountType: sharedbu.AccountType = .phone

    private let otpStatusSubject = PublishSubject<OtpStatus>()

    private let disposeBag = DisposeBag()

    private let getSystemStatusUseCase: ISystemStatusUseCase
    private let playerDataUseCase: PlayerDataUseCase
    private let playerConfiguration: PlayerConfiguration
    private let withdrawalAppService: IWithdrawalAppService

    private var isFirstLoad = true

    init(
        _ getSystemStatusUseCase: ISystemStatusUseCase,
        _ playerDataUseCase: PlayerDataUseCase,
        _ playerConfiguration: PlayerConfiguration,
        _ withdrawalAppService: IWithdrawalAppService)
    {
        self.getSystemStatusUseCase = getSystemStatusUseCase
        self.playerDataUseCase = playerDataUseCase
        self.playerConfiguration = playerConfiguration
        self.withdrawalAppService = withdrawalAppService
    }

    func setup(_ otpServiceUnavailable: (() -> Void)?) {
        setupOTPServiceStatusRefreshing(otpServiceUnavailable)

        fetchOTPStatus()
    }

    private func setupOTPServiceStatusRefreshing(_ allMethodsOnUnavailable: (() -> Void)?) {
        let getOtpStatusStream = otpStatusSubject
            .asDriver(onErrorRecover: { [weak self] error in
                self?.errorsSubject
                    .onNext(error)

                return Driver.just(OtpStatus(isMailActive: false, isSmsActive: false))
            })

        let getPlayerContactInfoStream = playerDataUseCase
            .loadPlayer()
            .map { player in
                player.playerInfo.contact
            }
            .asDriver(onErrorRecover: { [weak self] error in
                self?.errorsSubject
                    .onNext(error)

                return .just(.init(email: nil, mobile: nil))
            })

        let selectedAccountTypeStream = $selectedAccountType.asDriver()

        Driver.combineLatest(
            getOtpStatusStream,
            getPlayerContactInfoStream,
            selectedAccountTypeStream)
            .do(onNext: { [weak self] _, _, _ in
                if self?.isLoading == true {
                    self?.isLoading = false
                }
            })
            .drive(onNext: { [weak self] otpStatus, contactInfo, selectedAccountType in
                guard
                    let self,
                    otpStatus.isMailActive || otpStatus.isSmsActive
                else {
                    allMethodsOnUnavailable?()
                    return
                }

                if
                    self.isFirstLoad,
                    !self.isMobileAvailable(otpStatus, contactInfo)
                {
                    self.selectedAccountType = .email
                    self.isFirstLoad = false
                    return
                }

                self.otpServiceAvailability = self.updateOtpServiceAvailability(
                    for: selectedAccountType,
                    otpStatus: otpStatus,
                    contactInfo: contactInfo)
            })
            .disposed(by: disposeBag)
    }

    private func isMobileAvailable(_ otpStatus: OtpStatus, _ contactInfo: PlayerInfo.Contact) -> Bool {
        if
            otpStatus.isSmsActive,
            let mobileInfo = contactInfo.mobile,
            mobileInfo.isNotEmpty
        {
            return true
        }
        else {
            return false
        }
    }

    private func updateOtpServiceAvailability(
        for contactType: sharedbu.AccountType,
        otpStatus: OtpStatus,
        contactInfo: PlayerInfo.Contact)
        -> WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
    {
        let isOtpActive: Bool
        let contactValue: String?
        let contactInfoHint: String
        let contactNotSetHint: String
        let otpInactiveHint: String

        switch contactType {
        case .phone:
            isOtpActive = otpStatus.isSmsActive
            contactValue = contactInfo.mobile
            contactInfoHint = Localize.string("common_otp_hint_mobile")
            contactNotSetHint = Localize.string("common_not_set_mobile")
            otpInactiveHint = Localize.string("register_step2_sms_inactive")

        case .email:
            isOtpActive = otpStatus.isMailActive
            contactValue = contactInfo.email
            contactInfoHint = Localize.string("common_otp_hint_email")
            contactNotSetHint = Localize.string("common_not_set_email")
            otpInactiveHint = Localize.string("register_step2_email_inactive")
        }

        if isOtpActive {
            if
                let contactValue,
                contactValue.isNotEmpty
            {
                return .available(contactInfoHint + "\n" + contactValue, true)
            }
            else {
                return .available(contactNotSetHint, false)
            }
        }
        else {
            return .unavailable(otpInactiveHint)
        }
    }

    private func fetchOTPStatus() {
        getSystemStatusUseCase
            .fetchOTPStatus()
            .subscribe(
                onSuccess: { [weak self] otpStatus in
                    self?.otpStatusSubject
                        .onNext(otpStatus)
                },
                onFailure: { [weak self] error in
                    self?.otpStatusSubject
                        .onError(error)
                })
            .disposed(by: disposeBag)
    }

    func requestOTP(
        bankCardID: String,
        onCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?)
    {
        Completable.from(
            withdrawalAppService
                .requestCryptoWalletVerification(walletId: bankCardID, type: selectedAccountType))
            .do(
                onSubscribe: { self.isOTPRequestInProgress = true },
                onDispose: { self.isOTPRequestInProgress = false })
            .subscribe(
                onCompleted: { onCompleted?(self.selectedAccountType) },
                onError: {
                    switch $0 {
                    case is WithdrawalDto.VerifyRequestErrorStatus:
                        self.fetchOTPStatus()
                    default:
                        self.errorsSubject.onNext($0)
                    }
                })
            .disposed(by: disposeBag)
    }

    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }
}

// MARK: - Only For Test.

extension WithdrawalOTPVerifyMethodSelectViewModel {
    @available(*, deprecated, message: "Only For Test.")
    func setIsFirstLoad(_ bool: Bool) {
        isFirstLoad = bool
    }
}
