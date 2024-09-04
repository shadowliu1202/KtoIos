import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

extension ChatHistoriesEditView: Inspecting { }

final class ChatHistoriesEditViewTests: XCBaseTestCase {
    func getViewModel() -> ChatHistoriesEditViewModel {
        let dummyPlayerConfig = mock(PlayerConfiguration.self)
        let stubAppService = mock(AbsCustomerServiceAppService.self)
        let viewModel = ChatHistoriesEditViewModel(stubAppService, dummyPlayerConfig)
    
        given(dummyPlayerConfig.localeTimeZone()) ~> { Foundation.TimeZone.autoupdatingCurrent }
    
        given(stubAppService.getHistories(page: any(), pageSize: any())) ~> {
            Single.just(CustomerServiceDTO.ChatHistories(
                totalCount: 2,
                histories: [
                    CustomerServiceDTO.ChatHistoriesHistory(createDate: ClockSystem().now(), title: "test1", roomId: ""),
                    CustomerServiceDTO.ChatHistoriesHistory(createDate: ClockSystem().now(), title: "test2", roomId: "")
                ]))
                .asWrapper()
        }
    
        viewModel.getChatHistory(1)
        return viewModel
    }
  
    func getSut(viewModel: ChatHistoriesEditViewModel) -> ChatHistoriesEditView<ChatHistoriesEditViewModel> {
        let sut = ChatHistoriesEditView<ChatHistoriesEditViewModel>(
            viewModel: viewModel,
            onSelectedRow: { _ in },
            onTapDelete: { })
        return sut
    }
  
    func test_givenUnSelectAnyRecord_thenDeleteButtonDisable_KTO_TC_116() {
        let viewModel = getViewModel()

        let sut = getSut(viewModel: viewModel)

        let exp = sut.inspection.inspect { view in
      
            let isButtonDisable = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButton")
                .button()
                .isDisabled()

            XCTAssertTrue(isButtonDisable)
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
  
    func test_givenSelectOneRecord_thenDeleteButtonDisplayOneItemAndEnable_KTO_TC_117() {
        let viewModel = getViewModel()

        let sut = getSut(viewModel: viewModel)

        let exp = sut.inspection.inspect { view in
            let list = try view
                .find(viewWithId: "list")
                .find(viewWithId: "item")
                .forEach()
            try list.first?.callOnTapGesture()
      
            let actualTitle = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButtonText")
                .text()
                .string()
      
            let expectTitle = Localize.string("common_delete") + "(1)"
      
            XCTAssertEqual(expect: expectTitle, actual: actualTitle)
      
            let isButtonDisable = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButton")
                .button()
                .isDisabled()

            XCTAssertFalse(isButtonDisable)
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
  
    func test_givenTapSelectAllButton_thenSelectedButtonDisplayCancelAllAndDeleteButtonDisplayDeleteAllAndEnable_KTO_TC_118() {
        let viewModel = getViewModel()
        viewModel.toggleSelectAll()
    
        let sut = getSut(viewModel: viewModel)
    
        let exp = sut.inspection.inspect { view in
            let actualDeleteButtonTitle = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButtonText")
                .text()
                .string()

            XCTAssertEqual(expect: Localize.string("common_delete_all"), actual: actualDeleteButtonTitle)
      
            let isButtonDisable = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButton")
                .button()
                .isDisabled()

            XCTAssertFalse(isButtonDisable)

            let actualSelectedButtonTitle = try view
                .find(viewWithId: "selectedButton")
                .find(viewWithId: "selectedcText")
                .text()
                .string()

            XCTAssertEqual(expect: Localize.string("common_unselect_all"), actual: actualSelectedButtonTitle)
        }
    
        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
  
    func test_givenAllItemsSelected_whenTapCancelAllButton_thenSelectButtonDisplaySelectAllAndDeleteButtonDisableAndAllRecordDisplayUnselect_KTO_TC_119(
    ) {
        let viewModel = getViewModel()
        viewModel.toggleSelectAll()
    
        let sut = getSut(viewModel: viewModel)

        let exp = sut.inspection.inspect { view in
            let actualSelectedButton = try view
                .find(viewWithId: "selectedButton")
                .button()
            try actualSelectedButton.tap()

            let actualSelectedButtonTitle = try view
                .find(viewWithId: "selectedButton")
                .find(viewWithId: "selectedcText")
                .text()
                .string()

            XCTAssertEqual(expect: Localize.string("common_select_all"), actual: actualSelectedButtonTitle)
      
            let isButtonDisable = try view
                .find(viewWithId: "deleteButton")
                .find(viewWithId: "asyncButton")
                .button()
                .isDisabled()

            XCTAssertTrue(isButtonDisable)
      
            XCTAssertEqual(expect: 0, actual: viewModel.selectedHistories.selectedItems.count)
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
  
    func test_givenAllItemsSelected_whenUnselectOneItem_thenUnselectItemDisplayUnselectAndSelectButtonDisplaySelectAll_KTO_TC_120(
    ) {
        let viewModel = getViewModel()
        viewModel.toggleSelectAll()
    
        let sut = getSut(viewModel: viewModel)

        let exp = sut.inspection.inspect { view in
            let list = try view
                .find(viewWithId: "list")
                .find(viewWithId: "item")
                .forEach()
            try list.first?.callOnTapGesture()
      
            let actualSelectedButtonTitle = try view
                .find(viewWithId: "selectedButton")
                .find(viewWithId: "selectedcText")
                .text()
                .string()

            XCTAssertEqual(expect: Localize.string("common_select_all"), actual: actualSelectedButtonTitle)
      
            XCTAssertEqual(expect: 1, actual: viewModel.selectedHistories.selectedItems.count)
        }

        ViewHosting.host(view: sut)

        wait(for: [exp], timeout: 30)
    }
}
