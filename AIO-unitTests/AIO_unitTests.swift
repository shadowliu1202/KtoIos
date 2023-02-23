import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class AIO_unitTests: XCTestCase {
  private lazy var sut = PromotionViewController.initFrom(storyboard: "Promotion")
  private let mockPromotionUseCase = mock(PromotionUseCase.self)
  private let now = Date()
  private lazy var startDate = now.adding(value: -1, byAdding: .day).convertToKotlinx_datetimeLocalDateTime()
  private lazy var endDate = now.adding(value: 1, byAdding: .day).convertToKotlinx_datetimeLocalDateTime()
  private lazy var vvipCoupon = BonusCoupon.VVIPCashback(
    property: BonusCoupon.Property(
      promotionId: "",
      bonusId: "",
      name: "ABC",
      issueNumber: 0,
      percentage: Percentage(percent: 20.0),
      amount: "100".toAccountCurrency(),
      endDate: endDate,
      betMultiple: 0,
      fixTurnoverRequirement: 0.0,
      validPeriod: ValidPeriod.Always(),
      couponStatus: CouponStatus.usable,
      updatedDate: startDate,
      informPlayerDate: now.toUTCOffsetDateTime(),
      minCapital: "10".toAccountCurrency()))

  override func setUp() {
    super.setUp()
    injectStubCultureCode(.CN)
    injectStubPlayerLoginStatus()
    Injectable
      .register(PromotionUseCase.self) { _ in
        self.mockPromotionUseCase
      }
  }

  override func tearDown() {
    super.tearDown()
  }

  private func givenPromotionUseCaseStubs(
    productPromotion: [PromotionEvent.Product],
    rebatePromotion: [PromotionEvent.Rebate],
    bonusCoupon: [BonusCoupon],
    VVIPCashbackPromotion: [PromotionEvent.VVIPCashback])
  {
    given(mockPromotionUseCase.getProductPromotionEvents()) ~> .just(productPromotion)
    given(mockPromotionUseCase.getRebatePromotionEvents()) ~> .just(rebatePromotion)
    given(mockPromotionUseCase.getBonusCoupons()) ~> .just(bonusCoupon)
    given(mockPromotionUseCase.getVVIPCashbackPromotionEvents()) ~> .just(VVIPCashbackPromotion)
  }

  func test_HasVVIPCashbackCoupon_InAllCouponPage_VVIPCouponIsDisplayed_KTO_TC_17() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon],
      VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    let cell = sut.tableView(sut.tableView, cellForRowAt: [1, 0]) as! UsableTableViewCell
    let stampIconImage = cell.stampIcon.image
    let assetsIamge = UIImage(named: "iconCrown")
    guard let actual = stampIconImage?.pngData(), let expect = assetsIamge?.pngData() else {
      XCTFail("Data should not be nil")
      return
    }
    XCTAssertEqual(expect, actual)

    XCTAssertTrue(cell.tagLabel.text!.contains("负盈利返现"))
  }
}
