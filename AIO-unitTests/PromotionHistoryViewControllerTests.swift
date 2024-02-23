import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionHistoryViewControllerTests: XCBaseTestCase {
  func dummyHistory() -> CouponHistory {
    .init(
      amount: 100.toAccountCurrency(),
      bonusLockReceivingStatus: .inProgress,
      promotionId: "",
      name: "",
      bonusId: "",
      type: .freeBet,
      receiveDate: Date().toLocalDateTime(.current),
      issue: 0,
      productType: .casino,
      percentage: .init(percent: 100),
      turnOverDetail: nil)
  }

  func test_HaveOnePromotionHistoryRecord_ShowOneRecord_KTO_TC_109() {
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
      viewModel: PromotionHistoryViewModel(
        stubUseCase,
        Injectable.resolveWrapper(PlayerConfiguration.self)))

    sut.loadViewIfNeeded()

    sut.viewModel.fetchData()

    XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
  }
}
