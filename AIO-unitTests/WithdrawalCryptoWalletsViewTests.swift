import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalCryptoWalletsViewModelProtocolMock: ObservableObject { }
extension WithdrawalCryptoWalletsView: Inspecting { }

final class WithdrawalCryptoWalletsViewTests: XCBaseTestCase {
  func test_HasNoCryptoWallet_DisplayAddWalletComponents_KTO_TC_172() {
    let stubViewModel = mock(WithdrawalCryptoWalletsViewModelProtocol.self)

    given(stubViewModel.supportLocale) ~> .China()
    given(stubViewModel.playerWallet) ~> .init(wallets: [], maxAmount: 5)
    given(stubViewModel.isUpToMaximum) ~> false

    let sut = WithdrawalCryptoWalletsView(viewModel: stubViewModel)

    let expectation = sut.inspection.inspect { view in
      let title = try? view.find(text: Localize.string("cps_set_crypto_account"))
      XCTAssertNotNil(title)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }
}
