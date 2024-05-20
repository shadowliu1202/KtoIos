import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalFiatWalletsViewModelProtocolMock: ObservableObject { }
extension WithdrawalFiatWalletsView: Inspecting { }

final class WithdrawalFiatWalletsViewTests: XCBaseTestCase {
    func test_HasNoFiatWallet_DisplayAddWalletComponents_KTO_TC_172() {
        let stubViewModel = mock(WithdrawalFiatWalletsViewModelProtocol.self)

        given(stubViewModel.supportLocale) ~> .China()
        given(stubViewModel.playerWallet) ~> .init(wallets: [], maxAmount: 3)
        given(stubViewModel.isUpToMaximum) ~> false

        let sut = WithdrawalFiatWalletsView(viewModel: stubViewModel)

        let expectation = sut.inspection.inspect { view in
            let title = try? view.find(text: Localize.string("withdrawal_setbankaccount_title"))
            XCTAssertNotNil(title)
        }

        ViewHosting.host(view: sut)

        wait(for: [expectation], timeout: 30)
    }
}
