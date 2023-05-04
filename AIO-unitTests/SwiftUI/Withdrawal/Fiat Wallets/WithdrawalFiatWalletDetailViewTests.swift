import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalFiatWalletDetailView: Inspecting { }
extension WithdrawalFiatWalletDetailViewModelProtocolMock: ObservableObject { }

final class WithdrawalFiatWalletDetailViewTests: XCTestCase {
  let stubViewModel = mock(WithdrawalFiatWalletDetailViewModelProtocol.self)

  override func setUp() {
    super.setUp()
    given(stubViewModel.realName) ~> ""
    given(stubViewModel.supportLocale) ~> .China()
    given(stubViewModel.isDeleteSuccess) ~> false
  }

  func dummyWallet(deletable: Bool) -> WithdrawalDto.FiatWallet {
    .init(
      walletId: "test",
      name: "Test",
      isDeletable: deletable,
      verifyStatus: .verified,
      bankAccount: .init(
        bankId: 0,
        branch: "",
        accountName: "",
        accountNumber: "",
        city: "",
        location: ""),
      limitation: .init(
        maxCount: 100,
        maxAmount: "1000".toAccountCurrency(),
        currentCount: 3,
        currentAmount: "10000".toAccountCurrency(),
        oneOffMinimumAmount: "10".toAccountCurrency(),
        oneOffMaximumAmount: "1000".toAccountCurrency()))
  }

  func test_WalletIsNotDeletable_NotDisplayDeleteButton_KTO_TC_173() {
    let sut = WithdrawalFiatWalletDetailView(
      viewModel: self.stubViewModel,
      wallet: dummyWallet(deletable: false))

    given(stubViewModel.wallet) ~> self.dummyWallet(deletable: false)

    let expectation = sut.inspection.inspect { view in
      let delete = try? view.find(button: Localize.string("withdrawal_bankcard_delete"))
      XCTAssertNil(delete)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_WalletIsDeletable_DisplayDeleteButton_KTO_TC_174() {
    let sut = WithdrawalFiatWalletDetailView(
      viewModel: self.stubViewModel,
      wallet: dummyWallet(deletable: true))

    given(stubViewModel.wallet) ~> self.dummyWallet(deletable: true)

    let expectation = sut.inspection.inspect { view in
      let delete = try? view.find(button: Localize.string("withdrawal_bankcard_delete"))
      XCTAssertNotNil(delete)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }
}
