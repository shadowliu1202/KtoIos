import XCTest
import SwiftUI
import ViewInspector
import SharedBu
@testable import ktobet_asia_ios_qat

class StarMergerViewTest: XCTestCase {
    let stubObject = StubStarMergerViewModel()
    
    func test_Get_Payment_Link_On_Success() throws {
        stubObject.paymentLink = CommonDTO.WebPath.init(path: "")
        
        testUI(testView: StarMergerView(viewModel: stubObject, { _ in })) { view in
            let submitButton = try view.find(viewWithId: "submitButton").button()
            
            XCTAssertFalse(submitButton.isDisabled())
        }
    }
    
    func test_Get_Payment_Link_Not_On_Success() throws {
        stubObject.paymentLink = nil
        
        testUI(testView: StarMergerView(viewModel: stubObject, { _ in })) { view in
            let submitButton = try view.find(viewWithId: "submitButton").button()
            
            XCTAssertTrue(submitButton.isDisabled())
        }
    }
}

extension StarMergerView: UITestable {}

class StubStarMergerViewModel: StarMergerViewModel {
    var amountRange: AmountRange?
    
    var paymentLink: CommonDTO.WebPath?
    
    func getGatewayInformation() {
        //do nothing.
    }
}
