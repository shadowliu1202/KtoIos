import XCTest
import Mockingbird
import SharedBu

@testable import ktobet_asia_ios_qat

final class PromotionFilterViewControllerTest: XCTestCase {
    let stubDataSource = mock(FilterPresentProtocol.self)
    
    func test_HasVVIPRebateCoupon_InPromtionFilterPage_VVIPCouponFilterIsDisplayed_KTO_TC_25() {
        let stubLocalStorageRepository = mock(LocalStorageRepository.self).initialize(nil)
        given(stubLocalStorageRepository.getCultureCode()) ~> "zh-cn"
        
        Injectable
            .register(LocalizeUtils.self) { resolver in
                return LocalizeUtils(localStorageRepo: stubLocalStorageRepository)
            }
        
        given(stubDataSource.getTitle()) ~> ""
        given(stubDataSource.itemText(any())) ~> { ($0 as! PromotionItem).title }
        given(stubDataSource.getDatasource()) ~> [PromotionPresenter.createInteractive(.vvipcashback)]
        
        let sut = makeSUT(
            PromotionFilterViewController.self,
            from: "Filter"
        ) { [unowned self] in
            $0.presenter = stubDataSource
        }

        XCTAssertEqual(1, sut.tableView.numberOfRows(inSection: 0))
        
        let cell = sut.tableView.cellForRow(at: [0, 0]) as? InteractiveCell
        let expect = "负盈利返现"
        let actual = cell?.titleLbl.text
        
        XCTAssertEqual(expect, actual)
    }
}
