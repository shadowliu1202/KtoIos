import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalCryptoWalletsViewControllerTests: XCBaseTestCase {
    let stubAlert = mock(AlertProtocol.self)

    func getStubViewModel() -> WithdrawalCryptoWalletsViewModelMock {
        mock(WithdrawalCryptoWalletsViewModel.self)
            .initialize(
                withdrawalService: mock(AbsWithdrawalAppService.self),
                playerConfig: PlayerConfigurationImpl(nil))
    }
  
    func dummyWallet(status: Wallet.VerifyStatus) -> WithdrawalDto.CryptoWallet {
        .init(
            name: "test",
            walletId: "test Id",
            isDeletable: false,
            verifyStatus: status,
            type: .eth,
            network: .erc20,
            address: UUID().uuidString,
            limitation: .init(
                maxCount: 0, maxAmount: .zero(),
                currentCount: 0, currentAmount: .zero(),
                oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()),
            remainTurnOver: .zero())
    }
  
    func test_HasThreeCryptoWallets_ClickAddButton_DisplayAlert_KTO_TC_157() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.playerWallet) ~> .init(
            wallets: (0..<5).map { _ in self.dummyWallet(status: .pending) },
            maxAmount: 5)

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        sut.popMaximumAlert()

        verify(
            stubAlert
                .show(
                    any(),
                    Localize.string("withdrawal_bankcard_add_overlimit", "5"),
                    confirm: any(), confirmText: any(),
                    cancel: any(), cancelText: any(),
                    tintColor: any()))
            .wasCalled()
    }

    func test_AtCryptoWalletsPageAndIsNotEditing_ClickVerifiedWallet_GoWithdrawalPage_KTO_TC_158() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.observeWallets()) ~> { }
        given(stubViewModel.errors()) ~> .never()

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        let mockNavigationController = FakeNavigationController(rootViewController: sut)

        sut.loadViewIfNeeded()

        sut.handleWalletSelect(dummyWallet(status: .verified), isEditing: false)

        let actual = mockNavigationController.lastNavigatedViewController

        XCTAssertTrue(actual is WithdrawalCryptoRequestStep1ViewController)
    }

    func test_AtCryptoWalletsPageAndIsNotEditing_ClickUnVerifiedWallet_DisplayAlert_KTO_TC_159() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.playerWallet) ~> .init(wallets: [], maxAmount: 5)

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        sut.handleWalletSelect(dummyWallet(status: .pending), isEditing: false)

        verify(
            stubAlert
                .show(
                    any(),
                    Localize.string("cps_security_alert"),
                    confirm: any(), confirmText: any(),
                    cancel: any(), cancelText: any(),
                    tintColor: any()))
            .wasCalled()
    }

    func test_AtCryptoWalletsPageAndIsEditing_ClickWallet_GoDetailPage_KTO_TC_160() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.observeWallets()) ~> { }
        given(stubViewModel.errors()) ~> .never()

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        let mockNavigationController = FakeNavigationController(rootViewController: sut)

        sut.loadViewIfNeeded()

        sut.handleWalletSelect(dummyWallet(status: .verified), isEditing: true)

        let actual = mockNavigationController.lastNavigatedViewController

        XCTAssertTrue(actual is WithdrawalCryptoWalletDetailViewController)
    }
}
