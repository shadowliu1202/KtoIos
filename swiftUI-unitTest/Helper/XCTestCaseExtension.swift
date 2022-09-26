import XCTest
import SwiftUI
import ViewInspector
@testable import ktobet_asia_ios_qat

extension XCTestCase {
    func testUI<TestView: View & UITestable>(testView: TestView, _ content: @escaping (InspectableView<ViewType.View<TestView>>) throws -> Void) {
        let exp = testView.inspection.inspect { view in
            try content(view)
        }
        
        ViewHosting.host(view: testView)
        wait(for: [exp], timeout: 300)
    }
}

extension Inspection: InspectionEmissary {}
