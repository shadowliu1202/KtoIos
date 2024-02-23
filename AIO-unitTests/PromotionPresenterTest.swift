import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class PromotionPresenterTest: XCBaseTestCase {
  func test_givenCNPlayer_thenDisplayVVIPOption_KTO_TC_25() {
    let presenter = PromotionPresenter(supportLocale: .China())
    let hasVVIPOption = presenter.conditions.contains(where: { $0.privilegeType == .vvipcashBack })
    
    XCTAssertTrue(hasVVIPOption)
  }
  
  func test_givenVNPlayer_thenNotDisplayVVIPOption_KTO_TC_953() {
    let presenter = PromotionPresenter(supportLocale: .Vietnam())
    let hasVVIPOption = presenter.conditions.contains(where: { $0.privilegeType == .vvipcashBack })
    
    XCTAssertFalse(hasVVIPOption)
  }
}
