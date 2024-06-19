import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension CryptoDepositViewModelProtocolMock: ObservableObject { }

final class CryptoSelectorViewControllerTests: XCBaseTestCase {
    private func getViewModel() -> CryptoDepositViewModel {
        let viewModel = mock(CryptoDepositViewModel.self)
            .initialize(depositService: mock(AbsDepositAppService.self))

        given(viewModel.errors()) ~> .never()
        given(viewModel.submitButtonDisable) ~> false
        given(viewModel.options) ~> []
        given(viewModel.fetchOptions()) ~> { }

        return viewModel
    }

    private func injectLocalizationPolicyUseCase() {
        let localizationPolicyUseCase = mock(LocalizationPolicyUseCase.self)
        given(localizationPolicyUseCase.getCryptoGuidance()) ~> .never()
        Injectable
            .register(LocalizationPolicyUseCase.self) { _ in
                localizationPolicyUseCase
            }
    }

    func test_TapVideoTutorialBtn_InCryptoSelectorPage_VideoTutorialIsDisplayed_KTO_TC_40() {
        let stubViewModel = getViewModel()

        let sut = CryptoSelectorViewController(viewModel: stubViewModel)

        makeItVisible(sut)

        sut.navigateToVideoTutorial()

        let expact = "\(CryptoVideoTutorialViewController.self)"
        let actual = "\(type(of: sut.presentedViewController!))"

        XCTAssertEqual(expact, actual)
    }

    func test_AtCNEnvironmentTapCryptoGuideText_InCryptoSelectorPage_CNCryptoGuideIsDisplayed_KTO_TC_1() {
        injectLocalizationPolicyUseCase()

        let stubViewModel = getViewModel()

        let sut = CryptoSelectorViewController(
            playerConfiguration: PlayerConfigurationImpl(SupportLocale.China().cultureCode()),
            viewModel: stubViewModel)

        makeItVisible(UINavigationController(rootViewController: sut))

        sut.loadViewIfNeeded()
        sut.navigateToGuide()

        let expect = "\(CryptoGuideViewController.self)"
        let actual = "\(type(of: sut.navigationController!.topViewController!))"

        XCTAssertEqual(expect, actual)
    }

    func test_AtVNEnvironmentTapCryptoGuideText_InCryptoSelectorPage_VNCryptoGuideIsDisplayed_KTO_TC_2() {
        injectLocalizationPolicyUseCase()

        let stubViewModel = getViewModel()

        let sut = CryptoSelectorViewController(
            playerConfiguration: PlayerConfigurationImpl(SupportLocale.Vietnam().cultureCode()),
            viewModel: stubViewModel)

        makeItVisible(UINavigationController(rootViewController: sut))

        sut.loadViewIfNeeded()
        sut.navigateToGuide()

        let expect = "\(CryptoGuideVNDViewController.self)"
        let actual = "\(type(of: sut.navigationController!.topViewController!))"

        XCTAssertEqual(expect, actual)
    }

    func test_TapSubmitBtn_InCryptoSelectorPage_DepositCryptoViewIsDisplayed() {
        let stubViewModel = getViewModel()

        let sut = CryptoSelectorViewController(viewModel: stubViewModel)

        makeItVisible(UINavigationController(rootViewController: sut))

        sut.loadViewIfNeeded()
        sut.navigateToDepositCryptoVC("")

        let expect = "\(DepositCryptoWebViewController.self)"
        let actual = "\(type(of: sut.navigationController!.topViewController!))"

        XCTAssertEqual(expect, actual)
    }

    func test_givenDepositCountOverLimit_InCryptoSelectPage_thenAlertRequestLater() {
        stubLocalizeUtils(.China())

        let playerDepositCountOverLimit = ExceptionFactory.shared.create(message: "", statusCode: "10101")

        let stubViewModel = mock(CryptoDepositViewModel.self)
            .initialize(
                depositService: mock(AbsDepositAppService.self))

        given(stubViewModel.errors()) ~> .just(playerDepositCountOverLimit)

        let stubAlert = mock(AlertProtocol.self)

        let sut = CryptoSelectorViewController(viewModel: stubViewModel, alert: stubAlert)

        sut.loadViewIfNeeded()

        verify(
            stubAlert.show(
                any(),
                "您有五个待处理的充值请求，请您过三分钟后再试",
                confirm: any(),
                confirmText: any(),
                cancel: any(),
                cancelText: any(),
                tintColor: any()))
            .wasCalled()
    }
}
