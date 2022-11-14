import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class PromotionFilterViewControllerTest: XCTestCase {
    private lazy var sut = PromotionFilterViewController.initFrom(storyboard: "Filter")
    let stubDataSource = mock(FilterPresentProtocol.self)
    
    override func setUp() {
        super.setUp()
        stubCultureCode()
    }
    
    func test_HasVVIPRebateCoupon_InPromtionFilterPage_VVIPCouponFilterIsDisplayed_KTO_TC_25() {
        
        given(stubDataSource.getTitle()) ~> ""
        given(stubDataSource.itemText(any())) ~> { ($0 as! PromotionItem).title }
        given(stubDataSource.getDatasource()) ~> [PromotionPresenter.createInteractive(.vvipcashback)]
        
        sut.presenter = stubDataSource
        sut.loadViewIfNeeded()

        XCTAssertEqual(1, sut.tableView.numberOfRows(inSection: 0))
        
        let cell = sut.tableView.cellForRow(at: [0, 0]) as? InteractiveCell
        let expect = "负盈利返现"
        let actual = cell?.titleLbl.text
        
        XCTAssertEqual(expect, actual)
    }
}
