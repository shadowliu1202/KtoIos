import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class ChatHistoriesEditViewTest: XCTestCase {
    func test_isSelectAll() {
        var sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [])
        XCTAssertTrue(sut.isSelectAll)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: ClockSystem().now(), title: "test1", roomId: "")
            ],
            totalHistories: 1)
        XCTAssertTrue(sut.isSelectAll)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [],
            totalHistories: 1)
        XCTAssertFalse(sut.isSelectAll)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [])
        XCTAssertFalse(sut.isSelectAll)
    }
  
    func test_selectedButtonText() {
        var sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [])
        XCTAssertEqual(
            expect: Localize.string("common_unselect_all"),
            actual: sut.selectedButtonText)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [CustomerServiceDTO.ChatHistoriesHistory(createDate: ClockSystem().now(), title: "test1", roomId: "")],
            totalHistories: 1)
        XCTAssertEqual(
            expect: Localize
                .string("common_unselect_all"),
            actual: sut.selectedButtonText)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [])
        XCTAssertEqual(
            expect: Localize
                .string("common_select_all"),
            actual: sut.selectedButtonText)
    }
  
    func test_deleteCount() {
        let createDate = ClockSystem().now()
        var sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [])
        XCTAssertEqual(expect: 0, actual: sut.deleteCount)
    
        sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ],
            totalHistories: 2)
        XCTAssertEqual(expect: 1, actual: sut.deleteCount)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ],
            totalHistories: 1)
        XCTAssertEqual(expect: 1, actual: sut.deleteCount)
    }
  
    func test_deleteButtonText() {
        let createDate = ClockSystem().now()
        var sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ],
            totalHistories: 1)
        XCTAssertEqual(
            expect: Localize.string("common_delete"),
            actual: sut.deleteButtonText)
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ],
            totalHistories: 1)
        XCTAssertEqual(
            expect: Localize.string("common_delete_all"),
            actual: sut.deleteButtonText)
    
        sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ],
            totalHistories: 2)
        XCTAssertEqual(
            expect: Localize.string("common_delete") + "(\(sut.deleteCount))",
            actual: sut.deleteButtonText)
    }
  
    func test_toggle() {
        var sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [])
        sut.toogle()
        XCTAssertEqual(
            expect: sut.mode,
            actual: SelectedHistories.SelectMode.include)
        XCTAssertEqual(
            expect: sut.selectedItems,
            actual: [])
    
        sut = SelectedHistories(
            mode: .include,
            selectedItems: [],
            totalHistories: 1)
        sut.toogle()
        XCTAssertEqual(
            expect: sut.mode,
            actual: SelectedHistories.SelectMode.exclude)
        XCTAssertEqual(
            expect: sut.selectedItems,
            actual: [])
    }
  
    func test_isSelect() {
        let createDate = ClockSystem().now()
        var sut = SelectedHistories(
            mode: .include,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ])
        XCTAssertTrue(sut.isSelect(CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")))

        sut = SelectedHistories(
            mode: .exclude,
            selectedItems: [
                CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")
            ])
        XCTAssertFalse(sut.isSelect(CustomerServiceDTO.ChatHistoriesHistory(createDate: createDate, title: "test1", roomId: "")))
    }
}
