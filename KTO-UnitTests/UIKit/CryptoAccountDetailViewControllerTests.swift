import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class CryptoAccountDetailViewControllerTests: XCTestCase {
  private func getCryptoBankCard(verifyStatus: PlayerBankCardVerifyStatus) -> CryptoBankCard {
    .init(
      bankCard: BankCardObject(
        id_: "123",
        name: "Test",
        status: 0,
        verifyStatus: verifyStatus),
      currency: .eth,
      walletAddress: "Test",
      createdUser: "Test",
      updatedUser: "Test",
      updatedDate: Date().toUTCOffsetDateTime(),
      cryptoNetwork: .erc20)
  }

  override class func tearDown() {
    super.tearDown()
    Injection.shared.registerAllDependency()
  }

  func test_CryptoBankCardIsVerified_InCyptoBankCardManagementPage_DeleteButtonIsDisplayed_KTO_TC_105() {
    injectStubCultureCode(.CN)

    let sut = CryptoAccountDetailViewController.initFrom(storyboard: "Withdrawal")

    sut.account = getCryptoBankCard(verifyStatus: .verified)

    sut.loadViewIfNeeded()

    XCTAssertFalse(sut.deleteButton.isHidden)
    XCTAssertEqual(sut.verifyStatusLabel.text, "本賬户已验证核可")
  }

  func test_CryptoBankCardIsOnHold_InCyptoBankCardManagementPage_DeleteButtonIsHidden_KTO_TC_106() {
    let sut = CryptoAccountDetailViewController.initFrom(storyboard: "Withdrawal")

    sut.account = getCryptoBankCard(verifyStatus: .onhold)

    sut.loadViewIfNeeded()

    XCTAssertTrue(sut.deleteButton.isHidden)
  }
}
