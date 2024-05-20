import Combine
import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalOTPVerifyMethodSelectViewControllerTests: XCBaseTestCase {
    func test_givenOTPServiceDown_whenInWithdrawalOTPVerifyMethodSelectPage_thenAlertPlayer_KTO_TC_185() {
        let stubGetSystemStatusUseCase = mock(ISystemStatusUseCase.self)
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        let stubPlayerConfiguration = mock(PlayerConfiguration.self)
        let dummyAbsWithdrawalAppService = mock(AbsWithdrawalAppService.self)

        let stubViewModel = WithdrawalOTPVerifyMethodSelectViewModel(
            stubGetSystemStatusUseCase,
            stubPlayerDataUseCase,
            stubPlayerConfiguration,
            dummyAbsWithdrawalAppService)

        let mockAlert = mock(AlertProtocol.self)

        let sut = WithdrawalOTPVerifyMethodSelectViewController(
            viewModel: stubViewModel,
            alert: mockAlert,
            bankCardID: "")

        given(stubGetSystemStatusUseCase.fetchOTPStatus()) ~> .just(.init(isMailActive: false, isSmsActive: false))
        given(stubPlayerDataUseCase.loadPlayer()) ~> .just(.init(
            gameId: "",
            playerInfo: .init(
                gameId: "",
                displayId: "",
                withdrawalName: "",
                level: 0,
                exp: .init(percent: 0),
                autoUseCoupon: false,
                contact: .init(email: nil, mobile: nil)),
            bindLocale: .China(),
            defaultProduct: nil))

        given(stubPlayerConfiguration.supportLocale) ~> .China()

        sut.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            verify(mockAlert.show(
                Localize.string("common_error"),
                Localize.string("cps_otp_service_down"),
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()))
                .wasCalled()
        }
    }
}
