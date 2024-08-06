import Mockingbird
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension TermsView: Inspecting {}

final class TermsViewTests: XCBaseTestCase {
    func test_HasTwoTerm_InTermsPage_TwoTermIsDisplayed() {
        let terms = mock(Terms.self)
        given(terms.title) ~> "title"
        given(terms.description) ~> "description"
        given(terms.terms) ~> [.init("123", "456"), .init("234", "567")]

        let sut = TermsView(presenter: terms)

        let expectation = sut.inspection.inspect { view in
            let items = view.findAll { inspectableView in
                try inspectableView.id() as! String == TermsView.Identifier.sections.rawValue
            }

            XCTAssertEqual(items.count, 2)
        }
        ViewHosting.host(view: sut)

        wait(for: [expectation])
    }
}
