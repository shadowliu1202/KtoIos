import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalRecordDetailMainViewControllerTests: XCBaseTestCase {
    func test_RecordIsFiat_DisplayWithdrawalRecordDetailView_KTO_TC_132() {
        let sut = WithdrawalRecordDetailMainViewController(displayId: "", paymentCurrencyType: .fiat)
        sut.loadViewIfNeeded()

        XCTAssert(sut.target is WithdrawalRecordDetailViewController)
    }

    func test_RecordIsCrypto_DisplayWithdrawalCryptoRecordDetailView_KTO_TC_133() {
        let sut = WithdrawalRecordDetailMainViewController(displayId: "", paymentCurrencyType: .crypto)
        sut.loadViewIfNeeded()

        XCTAssert(sut.target is WithdrawalCryptoRecordDetailViewController)
    }
}
