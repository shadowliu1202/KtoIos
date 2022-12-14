import XCTest
import Mockingbird
import ViewInspector
import SharedBu

@testable import ktobet_asia_ios_qat

extension SelectingMock: ObservableObject { }

extension ItemSelector: Inspecting { }
extension ItemSelector.Item: Inspectable { }

final class ItemSelectorTests: XCTestCase {
    
    func buildDummySelectable(_ index: [Int]) -> [SelectableMock] {
        index.map {
            let stub = mock(Selectable.self)
            
            given(stub.identity) ~> "\($0)"
            given(stub.title) ~> "Test_\($0)"
            given(stub.image) ~> nil
            
            return stub
        }
    }
    
    func buildStubSelecting(
        count: Int,
        selectedIndex: [Int] = []
    ) -> SelectingMock {
        
        let stubSelecting = mock(Selecting.self)
        
        given(stubSelecting.dataSource) ~> self.buildDummySelectable((0..<count).map { $0 })
        given(stubSelecting.selectedItems) ~> self.buildDummySelectable(selectedIndex)
        
        return stubSelecting
    }
    
    func test_AllowMultipleSelectionIsTrue_CanSelectMultiple() {
        let stubSelecting = buildStubSelecting(count: 4)

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: false,
            selectAtLeastOne: false,
            allowMultipleSelection: true
        )

        let expectation = sut.inspection.inspect { view in
            let forEach = try view
                .vStack()
                .forEach(2)
            
            try (0...1).forEach {
                let row = try forEach
                    .view(ItemSelector<SelectingMock>.Item.self, $0)
                    .vStack()
                
                try row.callOnTapGesture()
            }

            let condition = stubSelecting
                .setSelectedItems(any(
                    [SelectableMock].self,
                    where: {
                        $0.contains(where: {
                            $0.identity == "0" ||
                            $0.identity == "1"
                        })
                    }
                ))
            
            verify(condition).wasCalled(2)
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AllowMultipleSelectionIsTrue_SelectTwoRow_TwoRowIsSelected() {
        let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0, 1])

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: false,
            selectAtLeastOne: false,
            allowMultipleSelection: true
        )

        let expectation = sut.inspection.inspect { view in
            let forEach = try view
                .vStack()
                .forEach(2)
            
            try (0...1).forEach {
                let imageName = try forEach
                    .view(ItemSelector<SelectingMock>.Item.self, $0)
                    .vStack()
                    .hStack(0)
                    .image(3)
                    .actualImage()
                    .name()
                
                XCTAssertEqual(imageName, "iconSingleSelectionSelected24")
            }
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AllowMultipleSelectionIsFalse_CanNotSelectMultiple() {
        let stubSelecting = buildStubSelecting(count: 4)

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: false,
            selectAtLeastOne: false,
            allowMultipleSelection: false
        )

        let expectation = sut.inspection.inspect { view in
            let forEach = try view
                .vStack()
                .forEach(2)
            
            try (0...1).forEach {
                let row = try forEach
                    .view(ItemSelector<SelectingMock>.Item.self, $0)
                    .vStack()
                
                try row.callOnTapGesture()
            }

            let condition = stubSelecting
                .setSelectedItems(any(
                    [SelectableMock].self,
                    where: {
                        $0.count == 1
                    }
                ))
            
            verify(condition).wasCalled(2)
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_HaveSelectAllIsTrue_CanSelectAllWhenPressAllButton() {
        injectStubCultureCode(.CN)
        
        let stubSelecting = buildStubSelecting(count: 4)

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: true,
            selectAtLeastOne: false,
            allowMultipleSelection: true
        )

        let expectation = sut.inspection.inspect { view in
            let button = try view
                .vStack()
                .hStack(0)
                .button(2)
            
            let text = try button
                .labelView()
                .localizedText(0)
                .string()
            
            XCTAssertEqual(text, "全选")
            
            try button.tap()

            let condition = stubSelecting
                .setSelectedItems(any(
                    [SelectableMock].self,
                    where: {
                        $0.count == 4
                    }
                ))
            
            verify(condition).wasCalled()
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_HaveSelectAllIsTrue_SelectAll_AllRowIsSelected() {
        injectStubCultureCode(.CN)
        
        let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0, 1, 2, 3])

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: true,
            selectAtLeastOne: false,
            allowMultipleSelection: true
        )

        let expectation = sut.inspection.inspect { view in
            let buttonText = try view
                .vStack()
                .hStack(0)
                .button(2)
                .labelView()
                .localizedText(0)
                .string()
            
            XCTAssertEqual(buttonText, "取消全选")
            
            let forEach = try view
                .vStack()
                .forEach(2)
            
            try (0...3).forEach {
                let imageName = try forEach
                    .view(ItemSelector<SelectingMock>.Item.self, $0)
                    .vStack()
                    .hStack(0)
                    .image(3)
                    .actualImage()
                    .name()
                
                XCTAssertEqual(imageName, "iconSingleSelectionSelected24")
            }
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_SelectAtLeastOneIsTrue_HaveOnSelection_CanNotCancelSelection() {
        let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0])

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: false,
            selectAtLeastOne: true,
            allowMultipleSelection: false
        )

        let expectation = sut.inspection.inspect { view in
            let forEach = try view
                .vStack()
                .forEach(2)
            
            let row0 = try forEach
                .view(ItemSelector<SelectingMock>.Item.self, 0)
                .vStack()
            
            try row0.callOnTapGesture()

            let condition = stubSelecting.setSelectedItems(any())
            
            verify(condition).wasNeverCalled()
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }

    func test_SelectAtLeastOneIsFalse_HaveOnSelection_CanCancelSelection() {
        let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0])

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: false,
            selectAtLeastOne: false,
            allowMultipleSelection: false
        )

        let expectation = sut.inspection.inspect { view in
            let forEach = try view
                .vStack()
                .forEach(2)
            
            let row0 = try forEach
                .view(ItemSelector<SelectingMock>.Item.self, 0)
                .vStack()
            
            try row0.callOnTapGesture()

            let condition = stubSelecting
                .setSelectedItems(any(
                    [SelectableMock].self,
                    where: {
                        $0.isEmpty
                    }
                ))
            
            verify(condition).wasCalled()
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AllRowIsSelected_ClickOneRow_SelectOneRowButDeselectOtherRow() {
        let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0, 1, 2, 3])

        let sut = ItemSelector(
            presenter: stubSelecting,
            accessory: .circle,
            haveSelectAll: true,
            selectAtLeastOne: true,
            allowMultipleSelection: true
        )

        let expectation = sut.inspection.inspect { view in
            let row1 = try view
                .vStack()
                .forEach(2)
                .view(ItemSelector<SelectingMock>.Item.self, 1)
                .vStack()
            
            try row1.callOnTapGesture()

            let condition = stubSelecting
                .setSelectedItems(any(
                    [SelectableMock].self,
                    where: {
                        $0.first?.identity == "1"
                    }
                ))
            
            verify(condition).wasCalled()
        }
        
        ViewHosting.host(view: sut)
        
        wait(for: [expectation], timeout: 10)
    }
}
