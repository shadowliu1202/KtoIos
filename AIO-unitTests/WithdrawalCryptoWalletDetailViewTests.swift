import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalCryptoWalletDetailView: Inspecting { }
extension WithdrawalCryptoWalletDetailViewModelProtocolMock: ObservableObject { }

extension WalletDetail: Inspecting { }

final class WithdrawalCryptoWalletDetailViewTests: XCBaseTestCase {
  let stubViewModel = mock(WithdrawalCryptoWalletDetailViewModelProtocol.self)

  override func setUp() {
    super.setUp()
    given(stubViewModel.supportLocale) ~> .China()
    given(stubViewModel.isDeleteSuccess) ~> false
    given(stubViewModel.isDeleteButtonDisable) ~> false
  }

  func dummyWallet(deletable: Bool) -> WithdrawalDto.CryptoWallet {
    .init(
      name: "test",
      walletId: "test id",
      isDeletable: deletable,
      verifyStatus: .pending,
      type: .eth,
      network: .erc20,
      address: "dsfjsjdflkjsdlfjksldfjlskdjflsk\ndlsdjflksdjflkjs",
      limitation: .init(
        maxCount: 0, maxAmount: .zero(),
        currentCount: 0, currentAmount: .zero(),
        oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()),
      remainTurnOver: .zero())
  }

  func test_CryptoBankCardIsVerified_InCyptoBankCardManagementPage_DeleteButtonIsDisplayed_KTO_TC_105() {
    let sut = WalletDetail(
      models: [],
      status: Localize.string("cps_account_status_verified"),
      deletable: true,
      deleteActionDisable: false,
      onDelete: nil)

    let exp = sut.inspection.inspect { view in

      let accountStatusText = try view.find(viewWithId: "accountStatusText").localizedText().string()
      let accountButtonIsExist = try view.isExistByVisibility(viewWithId: "deleteAccountButton")

      let expect = Localize.string("cps_account_status_verified")

      XCTAssertEqual(expect, accountStatusText)
      XCTAssertTrue(accountButtonIsExist)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }

  func test_CryptoBankCardIsOnHold_InCyptoBankCardManagementPage_DeleteButtonIsHidden_KTO_TC_106() {
    let sut = WalletDetail(
      models: [],
      status: "",
      deletable: false,
      deleteActionDisable: false,
      onDelete: nil)

    let exp = sut.inspection.inspect { view in
      let accountButtonIsExist = try view
        .isExistByVisibility(viewWithId: "deleteAccountButton")

      XCTAssertFalse(accountButtonIsExist)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }

  func test_WalletIsNotDeletable_NotDisplayDeleteButton_KTO_TC_173() {
    let sut = WithdrawalCryptoWalletDetailView(
      viewModel: self.stubViewModel,
      wallet: dummyWallet(deletable: false))

    given(stubViewModel.wallet) ~> self.dummyWallet(deletable: false)

    let expectation = sut.inspection.inspect { view in
      let empty = try view
        .find(viewWithId: "deleteAccountButton")
        .modifier(VisibilityModifier.self)
        .emptyView()

      XCTAssertNotNil(empty)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_WalletIsDeletable_DisplayDeleteButton_KTO_TC_174() {
    let sut = WithdrawalCryptoWalletDetailView(
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
