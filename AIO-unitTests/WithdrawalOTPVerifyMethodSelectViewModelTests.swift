import Combine
import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios

@MainActor
final class WithdrawalOTPVerifyMethodSelectViewModelTests: XCBaseTestCase {
    private let notSetContactInfoPlayer = Player(
        gameId: "",
        playerInfo: .init(
            gameId: "",
            displayId: "",
            withdrawalName: "",
            level: 1,
            exp: .init(percent: 0),
            autoUseCoupon: false,
            contact: .init(email: nil, mobile: nil)),
        bindLocale: .China(),
        defaultProduct: nil)

    private var cancellables = Set<AnyCancellable>()

    func test_givenMobileVerificationAvaildAndMobileNotSet_thenDisplayHintAndHideOTPRequestButton_KTO_TC_186() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: false, isSmsActive: true))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)

        sut.selectedAccountType = .phone
        sut.setIsFirstLoad(false)
        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$otpServiceAvailability
                .dropFirst()
                .sink { actual in
                    let expect = WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
                        .available(Localize.string("common_not_set_mobile"), false)

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }

    func test_givenEmailVerificationAvaildAndEmailNotSet_thenDisplayHintAndHideOTPRequestButton_KTO_TC_187() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: true, isSmsActive: false))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)
        sut.selectedAccountType = .email

        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$otpServiceAvailability
                .dropFirst()
                .sink { actual in
                    let expect = WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
                        .available(Localize.string("common_not_set_email"), false)

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }

    func test_givenMobileVerificationUnavailed_thenDisplayHintAndHideOTPRequestButton_KTO_TC_188() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: true, isSmsActive: false))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)

        sut.selectedAccountType = .phone
        sut.setIsFirstLoad(false)
        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$otpServiceAvailability
                .dropFirst()
                .sink { actual in
                    let expect = WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
                        .unavailable(Localize.string("register_step2_sms_inactive"))

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }

    func test_givenEmailVerificationUnavailed_thenDisplayHintAndHideOTPRequestButton_KTO_TC_189() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: false, isSmsActive: true))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)
        sut.selectedAccountType = .email

        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$otpServiceAvailability
                .dropFirst()
                .sink { actual in
                    let expect = WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
                        .unavailable(Localize.string("register_step2_email_inactive"))

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }

    func test_givenMobileVerificationUnavailed_thenDefaultSelectedAccountTypeIsEmail_KTO_TC_192() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: true, isSmsActive: false))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)

        sut.selectedAccountType = .phone
        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$selectedAccountType
                .dropFirst()
                .sink { actual in
                    let expect = sharedbu.AccountType.email

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }

    func test_givenMobileVerificationAvaildAndMobileNotSet_thenDefaultSelectedAccountTypeIsEmail_KTO_TC_193() async {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let dummyPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            dummyPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        given(stubGetSystemStatusUseCase.isOtpBlocked()) ~> .just(.init(isMailActive: false, isSmsActive: true))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(self.notSetContactInfoPlayer)

        sut.selectedAccountType = .phone
        sut.setup(nil)

        await withCheckedContinuation { continuation in
            sut.$selectedAccountType
                .dropFirst()
                .sink { actual in
                    let expect = sharedbu.AccountType.email

                    XCTAssertEqual(expect, actual)
                    continuation.resume()
                }
                .store(in: &cancellables)
        }
    }
}
