import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios

final class WithdrawalCryptoWalletsViewControllerTests: XCBaseTestCase {
    let stubAlert = mock(AlertProtocol.self)
    let mockAppService = mock(AbsWithdrawalAppService.self)

    func getStubViewModel() -> WithdrawalCryptoWalletsViewModelMock {
        given(mockAppService.getWalletSupportCryptoTypes()) ~> .init([])

        return mock(WithdrawalCryptoWalletsViewModel.self)
            .initialize(
                withdrawalService: mockAppService,
                playerConfig: PlayerConfigurationImpl(nil)
            )
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
                oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()
            ),
            remainTurnOver: .zero()
        )
    }

    func test_HasThreeCryptoWallets_ClickAddButton_DisplayAlert_KTO_TC_157() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.playerWallet) ~> .init(
            wallets: (0 ..< 5).map { _ in self.dummyWallet(status: .pending) },
            maxAmount: 5
        )

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        sut.popMaximumAlert()

        verify(
            stubAlert
                .show(
                    any(),
                    Localize.string("withdrawal_bankcard_add_overlimit", "5"),
                    confirm: any(), confirmText: any(),
                    cancel: any(), cancelText: any(),
                    tintColor: any()
                ))
                .wasCalled()
    }

    func test_AtCryptoWalletsPageAndIsNotEditing_ClickVerifiedAndSupportedWallet_GoWithdrawalPage_KTO_TC_158() {
        let wallet = dummyWallet(status: .verified)
        let stubViewModel = getStubViewModel()
        given(stubViewModel.observeWallets()) ~> {}
        given(stubViewModel.isValidWallet(wallet: wallet)) ~> true
        given(stubViewModel.errors()) ~> .never()

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        let mockNavigationController = FakeNavigationController(rootViewController: sut)

        sut.loadViewIfNeeded()

        sut.handleWalletSelect(wallet, isEditing: false)

        let actual = mockNavigationController.lastNavigatedViewController

        XCTAssertTrue(actual is WithdrawalCryptoRequestStep1ViewController)
    }

    func test_AtCryptoWalletsPageAndIsNotEditing_ClickVerifiedAndNotSupportedWallet_NotifyNotSupportedCurrency_KTO_TC_1833() {
        let wallet = dummyWallet(status: .verified)
        let stubViewModel = getStubViewModel()
        given(stubViewModel.observeWallets()) ~> {}
        given(stubViewModel.isValidWallet(wallet: wallet)) ~> false
        given(stubViewModel.errors()) ~> .never()

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        sut.loadViewIfNeeded()

        sut.handleWalletSelect(wallet, isEditing: false)

        verify(
            stubAlert
                .show(
                    any(),
                    Localize.string("withdrawal_not_supported_crypto"),
                    confirm: any(), confirmText: any(),
                    cancel: any(), cancelText: any(),
                    tintColor: any()
                ))
                .wasCalled()
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
                    tintColor: any()
                ))
                .wasCalled()
    }

    func test_AtCryptoWalletsPageAndIsEditing_ClickWallet_GoDetailPage_KTO_TC_160() {
        let stubViewModel = getStubViewModel()
        given(stubViewModel.observeWallets()) ~> {}
        given(stubViewModel.errors()) ~> .never()

        let sut = WithdrawalCryptoWalletsViewController(viewModel: stubViewModel, alert: stubAlert)

        let mockNavigationController = FakeNavigationController(rootViewController: sut)

        sut.loadViewIfNeeded()

        sut.handleWalletSelect(dummyWallet(status: .verified), isEditing: true)

        let actual = mockNavigationController.lastNavigatedViewController

        XCTAssertTrue(actual is WithdrawalCryptoWalletDetailViewController)
    }
}
