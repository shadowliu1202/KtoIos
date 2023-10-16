import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension SelectingMock: ObservableObject { }

extension ItemSelector: Inspecting { }

final class ItemSelectorTests: XCBaseTestCase {
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
    selectedIndex: [Int] = [])
    -> SelectingMock
  {
    let stubSelecting = mock(Selecting.self)

    given(stubSelecting.dataSource) ~> self.buildDummySelectable((0..<count).map { $0 })
    given(stubSelecting.selectedItems) ~> self.buildDummySelectable(selectedIndex)

    return stubSelecting
  }

  func test_AllowMultipleSelectionIsTrue_CanSelectMultiple() {
    let stubSelecting = buildStubSelecting(count: 4)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: false,
      selectAtLeastOne: false,
      allowMultipleSelection: true)

    let simulatedTapIndex = [0, 1]

    let expectation = sut.inspection.inspect { view in
      let forEach = try view
        .vStack()
        .forEach(2)

      try simulatedTapIndex.forEach {
        let row = try forEach
          .view(ItemSelector.Item.self, $0)
          .vStack()

        try row.callOnTapGesture()
      }

      XCTAssertEqual(sut.selectedItems.count, 2)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_AllowMultipleSelectionIsTrue_SelectTwoRow_TwoRowIsSelected() {
    let selectedIndex = [0, 1]
    let stubSelecting = buildStubSelecting(count: 4, selectedIndex: selectedIndex)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: false,
      selectAtLeastOne: false,
      allowMultipleSelection: true)

    let expectation = sut.inspection.inspect { view in
      let forEach = try view
        .vStack()
        .forEach(2)

      try selectedIndex.forEach {
        let imageName = try forEach
          .view(ItemSelector.Item.self, $0)
          .vStack()
          .hStack(0)
          .image(3)
          .actualImage()
          .name()

        XCTAssertEqual(imageName, "iconDoubleSelectionSelected24")
      }
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_AllowMultipleSelectionIsFalse_CanNotSelectMultiple() {
    let stubSelecting = buildStubSelecting(count: 4)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: false,
      selectAtLeastOne: false,
      allowMultipleSelection: false)

    let simulatedTapIndex = [0, 1]

    let expectation = sut.inspection.inspect { view in
      let forEach = try view
        .vStack()
        .forEach(2)

      try simulatedTapIndex.forEach {
        let row = try forEach
          .view(ItemSelector.Item.self, $0)
          .vStack()

        try row.callOnTapGesture()
      }

      XCTAssertEqual(sut.selectedItems.count, 1)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_HaveSelectAllIsTrue_CanSelectAllWhenPressAllButton() {
    injectStubCultureCode(.CN)

    let stubSelecting = buildStubSelecting(count: 4)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: true,
      selectAtLeastOne: false,
      allowMultipleSelection: true)

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

      XCTAssertEqual(sut.selectedItems.count, 4)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_HaveSelectAllIsTrue_SelectAll_AllRowIsSelected() {
    injectStubCultureCode(.CN)

    let selectedIndex = [0, 1, 2, 3]
    let stubSelecting = buildStubSelecting(count: 4, selectedIndex: selectedIndex)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: true,
      selectAtLeastOne: false,
      allowMultipleSelection: true)

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

      try selectedIndex.forEach {
        let imageName = try forEach
          .view(ItemSelector.Item.self, $0)
          .vStack()
          .hStack(0)
          .image(3)
          .actualImage()
          .name()

        XCTAssertEqual(imageName, "iconDoubleSelectionSelected24")
      }
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_SelectAtLeastOneIsTrue_HaveOnSelection_CanNotCancelSelection() {
    let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0])

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: false,
      selectAtLeastOne: true,
      allowMultipleSelection: false)

    let expectation = sut.inspection.inspect { view in
      let forEach = try view
        .vStack()
        .forEach(2)

      let row0 = try forEach
        .view(ItemSelector.Item.self, 0)
        .vStack()

      try row0.callOnTapGesture()

      XCTAssertEqual(sut.selectedItems.count, 1)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_SelectAtLeastOneIsFalse_HaveOnSelection_CanCancelSelection() {
    let stubSelecting = buildStubSelecting(count: 4, selectedIndex: [0])

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: false,
      selectAtLeastOne: false,
      allowMultipleSelection: false)

    let expectation = sut.inspection.inspect { view in
      let forEach = try view
        .vStack()
        .forEach(2)

      let row0 = try forEach
        .view(ItemSelector.Item.self, 0)
        .vStack()

      try row0.callOnTapGesture()

      XCTAssertEqual(sut.selectedItems.count, 0)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_AllRowIsSelected_ClickOneRow_SelectOneRowButDeselectOtherRow() {
    let selectedIndex = [0, 1, 2, 3]
    let stubSelecting = buildStubSelecting(count: 4, selectedIndex: selectedIndex)

    let sut = ItemSelector(
      dataSource: stubSelecting.dataSource,
      selectedItems: .init(wrappedValue: stubSelecting.selectedItems),
      haveSelectAll: true,
      selectAtLeastOne: true,
      allowMultipleSelection: false)

    let expectation = sut.inspection.inspect { view in
      let row1 = try view
        .vStack()
        .forEach(2)
        .view(ItemSelector.Item.self, 1)
        .vStack()

      try row1.callOnTapGesture()

      XCTAssertEqual(sut.selectedItems.count, 1)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }
}
