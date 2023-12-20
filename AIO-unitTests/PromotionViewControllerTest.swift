import Mockingbird
import RxSwift
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionViewControllerTest: XCBaseTestCase {
  private let mockPromotionUseCase = mock(PromotionUseCase.self)
  private let now = Date()

  private lazy var sut = PromotionViewController.initFrom(storyboard: "Promotion")
  private lazy var startDate = now.adding(value: -1, byAdding: .day).toLocalDateTime(.current)
  private lazy var endDate = now.adding(value: 1, byAdding: .day).toLocalDateTime(.current)

  private lazy var vvipPromotion = PromotionEvent.VVIPCashback(
    promotionId: "",
    issueNumber: 0,
    informPlayerDate: now.toLocalDateTime(.current),
    percentage: Percentage(percent: 20.0),
    maxBonus: Promotion.companion.create(amount: "100.0".toAccountCurrency()),
    endDate: now.adding(value: 1, byAdding: .day).toUTCOffsetDateTime())

  override func setUp() {
    super.setUp()
    stubLocalizeUtils(.China())
    Injectable
      .register(PromotionUseCase.self) { _ in
        self.mockPromotionUseCase
      }
  }

  private func vvipCoupon(delay: Double = 0) -> BonusCoupon.VVIPCashback {
    .init(property: .init(
      promotionId: "",
      bonusId: "",
      name: "ABC",
      issueNumber: 0,
      percentage: Percentage(percent: 20.0),
      amount: "100".toAccountCurrency(),
      endDate: endDate,
      betMultiple: 0,
      fixTurnoverRequirement: 0.0,
      validPeriod: delay == 0 ?
        .Always() : .Duration(
          start: Date().toUTCOffsetDateTime(),
          end: Date().addingTimeInterval(delay).toUTCOffsetDateTime()),
      couponStatus: CouponStatus.usable,
      updatedDate: startDate,
      informPlayerDate: now.toUTCOffsetDateTime(),
      minCapital: "10".toAccountCurrency()))
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
      bonusCoupon: [vvipCoupon()],
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

  func test_HasOneVVIPCashbackCoupon_InAllCouponPage_VVIPTabIsDisplayedWithNumber1_KTO_TC_18() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    XCTAssertTrue(
      sut.viewModel.promotionTags
        .contains(where: { $0.name == "负盈利返现(1)" }))
  }

  func test_HasZeroVVIPCashbackCouponAndZeroVVIPPromotionEvent_InMainPage_VVIPCashbackTabIsNotDisplayed_KTO_TC_19() {
    givenPromotionUseCaseStubs(productPromotion: [], rebatePromotion: [], bonusCoupon: [], VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    XCTAssertFalse(
      sut.viewModel.promotionTags
        .contains(where: { $0.name.contains("负盈利返现") }))
  }

  func test_HasOneVVIPCashbackCoupon_InVVIPCouponPage_OneCashbackCouponIsDisplayed_KTO_TC_26() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())
    sut.viewModel.setCouponFilter(PromotionFilter.cashBack, [])

    let cell = sut.tableView(sut.tableView, cellForRowAt: [0, 0]) as! UsableTableViewCell
    let stampIconImage = cell.stampIcon.image
    let assetsIamge = UIImage(named: "iconCrown")
    guard let actual = stampIconImage?.pngData(), let expect = assetsIamge?.pngData() else {
      XCTFail("Data should not be nil")
      return
    }
    XCTAssertEqual(expect, actual)

    XCTAssertTrue(cell.tagLabel.text!.contains("负盈利返现"))

    XCTAssertEqual(1, sut.tableView.numberOfRows(inSection: 0))
  }

  func test_HasOneVVIPPromotionEvent_InAllCouponPage_VVIPTabIsDisplayedWithNumber1_KTO_TC_27() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [],
      VVIPCashbackPromotion: [vvipPromotion])

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

  func test_HasOneVVIPPromotionEvent_InAllCouponPage_VVIPTabIsDisplayedWithNumber1_KTO_TC_28() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [],
      VVIPCashbackPromotion: [vvipPromotion])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    XCTAssertTrue(
      sut.viewModel.promotionTags
        .contains(where: { $0.name == "负盈利返现(1)" }))
  }

  func test_HasOneVVIPPromotionEvent_InVVIPCouponPage_OneVVIPPromotionEventIsDisplayed_KTO_TC_33() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [],
      VVIPCashbackPromotion: [vvipPromotion])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())
    sut.viewModel.setCouponFilter(PromotionFilter.cashBack, [])

    let cell = sut.tableView(sut.tableView, cellForRowAt: [0, 0]) as! UsableTableViewCell
    let stampIconImage = cell.stampIcon.image
    let assetsIamge = UIImage(named: "iconCrown")
    guard let actual = stampIconImage?.pngData(), let expect = assetsIamge?.pngData() else {
      XCTFail("Data should not be nil")
      return
    }
    XCTAssertEqual(expect, actual)

    XCTAssertTrue(cell.tagLabel.text!.contains("负盈利返现"))

    XCTAssertEqual(1, sut.tableView.numberOfRows(inSection: 0))
  }

  func test_HasOneVVIPCashbackCoupon_InAllCouponPage_VVIPTabIsAfterManualTabAndBeforeFreebetTab_KTO_TC_37() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    let indexManual = sut.viewModel.promotionTags.firstIndex(where: { $0.name.contains("手动领取") })!
    let indexVVIPCashback = sut.viewModel.promotionTags.firstIndex(where: { $0.name.contains("负盈利返现") })!
    let indexFreebet = sut.viewModel.promotionTags.firstIndex(where: { $0.name.contains("免费金") })!
    XCTAssertGreaterThan(indexVVIPCashback, indexManual)
    XCTAssertLessThan(indexVVIPCashback, indexFreebet)
  }

  func test_HasOneVVIPCashbackCoupon_InAllCouponPage_ManualTabCountShouldBeOne_KTO_TC_38() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    let manualTab = sut.viewModel.promotionTags.first(where: { $0.name.contains("手动领取") })!
    XCTAssertEqual(1, manualTab.count)
  }

  func test_HasOneVVIPPromotionEventAndOneVVIPCashbackCouponWithoutOtherCoupons_AllTabCountShouldBeThree() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [vvipPromotion])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    let allTab = sut.viewModel.promotionTags.first(where: { $0.name.contains("全部") })!
    XCTAssertEqual(3, allTab.count)
  }

  func test_PromotionFilterCasesCount_Equal_TabsCount() {
    givenPromotionUseCaseStubs(
      productPromotion: [],
      rebatePromotion: [],
      bonusCoupon: [vvipCoupon()],
      VVIPCashbackPromotion: [vvipPromotion])

    sut.loadViewIfNeeded()
    sut.viewModel.trigerRefresh.onNext(())

    let expect = PromotionFilter.allCases.count

    let actual = sut.viewModel.promotionTags.count

    XCTAssertEqual(expect, actual)
  }
}
