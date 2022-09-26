import XCTest
import SwiftUI
import ViewInspector
@testable import ktobet_asia_ios_qat

class ExpandableBlockTest: XCTestCase {
    func test_Guide_Link_isExpanded() throws {
        testUI(testView: ExpandableBlock(title: "Title", content: { Text("content") })) { view in
            let header = try view.find(viewWithId: "blockHeader").vStack()
            try header.callOnTapGesture()
            let rows = try view.find(viewWithId: "blockContent").text()
            XCTAssertNotNil(rows)
        }
    }
    
    func test_Guide_Link_isFolded() throws {
        testUI(testView: ExpandableBlock(title: "Title", content: { Text("content") })) { view in
            let rows = try? view.find(viewWithId: "blockContent").text()
            XCTAssertNil(rows)
        }
    }
    
}

extension ExpandableBlock: UITestable {}


