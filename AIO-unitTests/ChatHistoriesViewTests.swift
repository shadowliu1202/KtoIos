import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class ChatHistoriesViewTests: XCTestCase {
    func getChatHistory(content: CustomerServiceDTO.Content) -> [CustomerServiceDTO.ChatMessage] {
        [
            .init(
                id: "1",
                speaker: .init(
                    type: .cs,
                    name: "cs"),
                createTime: ClockSystem().now(),
                contents: [
                    content
                ],
                isProcessing: false),
        ]
    }
  
    func test_givenTextTypeContent_thenDisplayTextContent() {
        let inspectWrapper = InspectWrapper {
            ChattingListView(
                messages: getChatHistory(
                    content: .init(
                        id: "1",
                        type: .text,
                        text: "实名验证要去哪里设定？",
                        textAttributes: nil,
                        image: nil)))
        }
    
        let expection = inspectWrapper.inspection.inspect { view in
            let actText = try view
                .find(viewWithId: "text")
                .text()
                .string()
      
            XCTAssertEqual(expect: "实名验证要去哪里设定？", actual: actText)
        }
    
        ViewHosting.host(view: inspectWrapper)
    
        wait(for: [expection], timeout: 30)
    }
  
    func test_givenImageTypeContent_thenDisplayImageContent() {
        let inspectWrapper = InspectWrapper {
            ChattingListView(
                messages: getChatHistory(
                    content: .init(
                        id: "1",
                        type: .image,
                        text: "",
                        textAttributes: nil,
                        image: ChatImage(path: "/image/chatting/64ae236755595818e492a924.jpg?type=1", inChat: false))))
        }
    
        let expection = inspectWrapper.inspection.inspect { view in
            let actImage = try view
                .find(viewWithId: "image")

            XCTAssertFalse(actImage.isEmpty)
        }
    
        ViewHosting.host(view: inspectWrapper)
    
        wait(for: [expection], timeout: 30)
    }
  
    func test_givenLinkTypeContent_thenDisplayLinkContent() {
        let inspectWrapper = InspectWrapper {
            ChattingListView(
                messages: getChatHistory(
                    content: .init(
                        id: "1",
                        type: .text,
                        text: "YT",
                        textAttributes: .init(
                            align: nil,
                            background: nil,
                            bold: nil,
                            color: nil,
                            font: nil,
                            image: nil,
                            italic: nil,
                            link: "https://www.youtube.com",
                            size: nil,
                            underline: nil),
                        image: nil)))
        }
    
        let expection = inspectWrapper.inspection.inspect { view in
            let actLink = try view
                .find(viewWithId: "link")
                .text()
                .string()

            XCTAssertEqual(expect: "https://www.youtube.com", actual: actLink)
        }
    
        ViewHosting.host(view: inspectWrapper)
    
        wait(for: [expection], timeout: 30)
    }
}
