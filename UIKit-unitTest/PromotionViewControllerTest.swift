import XCTest
import Mockingbird
import RxSwift
import SharedBu

@testable import ktobet_asia_ios_qat

final class PromotionViewControllerTest: XCTestCase {
    let mockPromotionUseCase = mock(PromotionUseCase.self)
    let now = Date()
    lazy var startDate = now.adding(value: -1, byAdding: .day).convertToKotlinx_datetimeLocalDateTime()
    lazy var endDate = now.adding(value: 1, byAdding: .day).convertToKotlinx_datetimeLocalDateTime()
    lazy var vvipCoupon = BonusCoupon.VVIPCashback(
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
            minCapital: "10".toAccountCurrency()
        )
    )
    
    override func setUp() {
        super.setUp()
        
        injectStubPlayerLoginStatus()
        
        Injectable
            .register(PromotionUseCase.self) { _ in
                self.mockPromotionUseCase
            }
        given(mockPromotionUseCase.getProductPromotionEvents()) ~> .just([])
        given(mockPromotionUseCase.getRebatePromotionEvents()) ~> .just([])
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_HasVVIPRebateCoupon_InAllCouponPage_VVIPCouponIsDisplayed_KTO_TC_17() {
        
        let sut = makeSUT(
            PromotionViewController.self,
            from: "Promotion"
        ) { [unowned self] _ in
            given(self.mockPromotionUseCase.getBonusCoupons()) ~> .just([self.vvipCoupon])
        }
        
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
    
    func test_HasOneVVIPRebateCoupon_InAllCouponPage_VVIPTabIsDisplayedWithNumber1_KTO_TC_18() {
        let sut = makeSUT(
            PromotionViewController.self,
            from: "Promotion"
        ) { [unowned self] _ in
            given(self.mockPromotionUseCase.getBonusCoupons()) ~> .just([self.vvipCoupon])
        }
        
        sut.viewModel.trigerRefresh.onNext(())
        let dropDown = sut.filterDropDwon!
        
        XCTAssertTrue(dropDown.tags.contains(where: {$0.name == "负盈利返现(1)"}))
    }
    
    func test_HasZeroVVIPRebateCoupon_InMainPage_VVIPCashbackTabIsNotDisplayed_KTO_TC_19() {
        let sut = makeSUT(
            PromotionViewController.self,
            from: "Promotion"
        ) { [unowned self] _ in
            given(self.mockPromotionUseCase.getBonusCoupons()) ~> .just([])
        }
        
        sut.viewModel.trigerRefresh.onNext(())
        let dropDown = sut.filterDropDwon!
        
        XCTAssertFalse(dropDown.tags.contains(where: {$0.name.contains("负盈利返现")}))
    }
    
    func test_HasOneVVIPCashbackCoupon_InVVIPCouponPage_OneCashbackCouponIsDisplayed_KTO_TC_26() {
        let sut = makeSUT(
            PromotionViewController.self,
            from: "Promotion"
        ) { [unowned self] _ in
            given(self.mockPromotionUseCase.getBonusCoupons()) ~> .just([self.vvipCoupon])
        }
        
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
}
