import XCTest
import SwiftUI
import ViewInspector

extension XCTestCase {
    func testUI<Wrapped: View & Inspectable>(wrappedView: Wrapped, _ content: @escaping (InspectableView<ViewType.View<TestWrapperView<Wrapped>>>) throws -> Void) {
        let sut = TestWrapperView.init(wrapped: wrappedView)
        let exp = sut.inspection.inspect { view in
            try content(view)
        }
        
        ViewHosting.host(view: sut)
        wait(for: [exp], timeout: 300)
    }
}
