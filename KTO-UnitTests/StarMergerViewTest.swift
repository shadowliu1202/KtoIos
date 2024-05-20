import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension StarMergerView: Inspecting { }

class StubStarMergerViewModel: StarMergerViewModel {
    var amountRange: AmountRange?
    var paymentLink: CommonDTO.WebPath?
    func getGatewayInformation() { }
}

class StarMergerViewTest: XCBaseTestCase {
    let stubObject = StubStarMergerViewModel()

    func test_Get_Payment_Link_On_Success() throws {
        stubObject.paymentLink = CommonDTO.WebPath(path: "")

        let sut = StarMergerView(viewModel: stubObject, { _ in })

        let exp = sut.inspection.inspect { view in
            let isSubmitButtonDisable = try view
                .find(viewWithId: "submitButton")
                .find(viewWithId: "asyncButton")
                .button()
                .isDisabled()

            XCTAssertFalse(isSubmitButtonDisable)
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }

    func test_Get_Payment_Link_Not_On_Success() throws {
        stubObject.paymentLink = nil

        let sut = StarMergerView(viewModel: stubObject, { _ in })

        let exp = sut.inspection.inspect { view in
            let submitButton = try view.find(viewWithId: "submitButton")

            XCTAssertTrue(submitButton.isDisabled())
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
}
