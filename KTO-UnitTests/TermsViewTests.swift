import Mockingbird
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension TermsView.Sections: Inspecting { }

final class TermsViewTests: XCBaseTestCase {
    func test_HasOneTerm_InTermsPage_OneTermIsDisplayed() {
        let stubPresenter = mock(SecurityPrivacyTerms.self)

        given(stubPresenter.dataSourceTerms) ~> [
            .init("123", "456")
        ]

        let sut = TermsView<SecurityPrivacyTerms>.Sections()

        let expectation = sut.inspection.inspect { view in
            let numberOfSections = try view
                .find(viewWithId: "sections")
                .forEach()
                .count

            XCTAssertEqual(numberOfSections, 1)
        }

        ViewHosting.host(
            view: sut.environmentObject(
                stubPresenter as SecurityPrivacyTerms))

        wait(for: [expectation], timeout: 30)
    }
}
