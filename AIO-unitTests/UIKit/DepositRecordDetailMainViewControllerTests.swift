import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class DepositRecordDetailMainViewControllerTests: XCBaseTestCase {
  func test_RecordIsFiat_DisplayDepositRecordDetailView_KTO_TC_88() {
    let sut = DepositRecordDetailMainViewController(displayId: "", paymentCurrencyType: .fiat)
    sut.loadViewIfNeeded()

    XCTAssert(sut.target is DepositRecordDetailViewController)
  }

  func test_RecordIsCrypto_DisplayDepositCryptoRecordDetailView_KTO_TC_91() {
    let sut = DepositRecordDetailMainViewController(displayId: "", paymentCurrencyType: .crypto)
    sut.loadViewIfNeeded()

    XCTAssert(sut.target is DepositCryptoRecordDetailViewController)
  }
}
