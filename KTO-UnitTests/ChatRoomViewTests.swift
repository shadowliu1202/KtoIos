import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

final class ChatRoomViewTests: XCTestCase {
    func test_whenHaveUnReadMessages_thenDisplayUnReadSeperator() {
        let inspectWrapper = InspectWrapper {
            ChattingListView(messages: [.unreadSeperator])
        }
    
        let expection = inspectWrapper.inspection.inspect { view in
            let isSeparatorExist = view.isExist(viewWithId: CustomerServiceDTO.ChatMessage.unreadSeperator.id)
      
            XCTAssertTrue(isSeparatorExist)
        }
    
        ViewHosting.host(view: inspectWrapper)
    
        wait(for: [expection], timeout: 30)
    }
}
