import Mockingbird
import XCTest

@testable import ktobet_asia_ios_qat

final class DropdownSelectorTests: XCBaseTestCase {
  func test_givenListExpandTrue_thenTableIsDisplayed() {
    let option = mock(DropdownSelectable.self)
    given(option.contentText) ~> "Amy"

    let sut = DropdownSelector(
      frame: .init(
        origin: .zero,
        size: .init(width: 100, height: 100)))
    sut.setItems([option])
    sut.listExpand(true)

    wait(for: sut.AnimationDuration)

    let isTableShow = sut.tableView.alpha == 1

    XCTAssertTrue(isTableShow)
  }

  func test2_givenListExpandFalse_thenTableIsHide() {
    let option = mock(DropdownSelectable.self)
    given(option.contentText) ~> "Amy"

    let sut = DropdownSelector(
      frame: .init(
        origin: .zero,
        size: .init(width: 100, height: 100)))
    sut.setItems([option])
    sut.listExpand(false)

    wait(for: sut.AnimationDuration)

    let isTableHide = sut.tableView.alpha == 0

    XCTAssertTrue(isTableHide)
  }

  func test_givenPreSelectedItem_inTitleText_thenTextIsEqualItemText() {
    let option = mock(DropdownSelectable.self)
    given(option.contentText) ~> "Amy"

    let sut = DropdownSelector(
      frame: .init(
        origin: .zero,
        size: .init(width: 100, height: 100)))
    sut.setItems([option])
    sut.setSelectedItem(option)

    let actual = sut.titleLabel.text
    XCTAssertEqual(actual, "Amy")
  }

  func test_givenSelectOneItem_inExpandList_thenSelectItemIsEqualThatOne() {
    let option1 = mock(DropdownSelectable.self)
    given(option1.contentText) ~> "Amy"
    given(option1.identity) ~> option1.contentText
    given(option1.isEqualTo(any())).will({
      option1.identity == $0.identity
    })
    let option2 = mock(DropdownSelectable.self)
    given(option2.contentText) ~> "Ben"
    given(option2.identity) ~> option2.contentText
    given(option2.isEqualTo(any())).will {
      option2.identity == $0.identity
    }

    let sut = DropdownSelector(
      frame: .init(
        origin: .zero,
        size: .init(width: 100, height: 100)))
    sut.setItems([option1, option2])
    sut.listExpand(true)

    wait(for: sut.AnimationDuration)

    sut.tableView.delegate?.tableView?(sut.tableView, didSelectRowAt: [0, 1])

    let actual = sut.getSelectedItem()!.isEqualTo(option2)
    XCTAssertTrue(actual)
  }
}
