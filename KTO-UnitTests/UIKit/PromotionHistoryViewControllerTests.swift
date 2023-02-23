import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionHistoryViewControllerTests: XCTestCase {
  func dummyHistory() -> CouponHistory {
    .init(
      amount: 100.toAccountCurrency(),
      bonusLockReceivingStatus: .inprogress,
      promotionId: "",
      name: "",
      bonusId: "",
      type: .freebet,
      receiveDate: Date().convertToKotlinx_datetimeLocalDateTime(),
      issue: 0,
      productType: .casino,
      percentage: .init(percent: 100),
      turnOverDetail: nil)
  }

  func test_HaveOnePromotionHistoryRecord_ShowOneRecord_KTO_TC_107() {
    let stubUseCase = mock(PromotionUseCase.self)

    given(stubUseCase.searchBonusCoupons(
      keyword: any(),
      from: any(),
      to: any(),
      productTypes: any(),
      privilegeTypes: any(),
      sortingBy: any(),
      page: any()))
      ~>
      .just(.init(
        summary: 100.toAccountCurrency(),
        totalCoupon: 1,
        couponHistory: [
          self.dummyHistory()
        ]))

    let sut = PromotionHistoryViewController.instantiate(
      viewModel: .init(
        promotionUseCase: stubUseCase,
        localRepo: Injectable.resolveWrapper(LocalStorageRepository.self)))

    sut.loadViewIfNeeded()

    XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
  }
}
