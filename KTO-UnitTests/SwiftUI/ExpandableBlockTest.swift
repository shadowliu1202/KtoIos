import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension ExpandableBlock: Inspecting { }

class ExpandableBlockTest: XCTestCase {
  func test_Guide_Link_isExpanded() throws {
    let sut = ExpandableBlock(title: "Title", content: { Text("content") })

    let exp = sut.inspection.inspect { view in
      let header = try view.find(viewWithId: "blockHeader").vStack()
      try header.callOnTapGesture()

      let rows = try view.find(viewWithId: "blockContent").text()
      XCTAssertNotNil(rows)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }

  func test_Guide_Link_isFolded() throws {
    let sut = ExpandableBlock(title: "Title", content: { Text("content") })

    let exp = sut.inspection.inspect { view in
      let rows = try? view.find(viewWithId: "blockContent").text()
      XCTAssertNil(rows)
    }

    ViewHosting.host(view: sut)

    wait(for: [exp], timeout: 30)
  }
}
