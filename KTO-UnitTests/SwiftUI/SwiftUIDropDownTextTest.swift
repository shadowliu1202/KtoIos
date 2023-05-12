import Combine
import Mockingbird
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension SwiftUIDropDownText: Inspecting { }

final class SwiftUIDropDownTextTest: XCBaseTestCase {
  private let publisher = PassthroughSubject<Void, Never>()
  private let stubDatas = ["中国银行", "中国工商银行", "中国农民银行", "中国建设银行", "交通银行", "中國信託", "玉山銀行"]

  func test_givenDropDownArrowVisible_thenDropDownArrowIsNotHidden() throws {
    let sut = SwiftUIDropDownText(
      placeHolder: "",
      textFieldText: .constant(""),
      items: [],
      featureType: .inputAssisted,
      dropDownArrowVisible: true)
      .environmentObject(SafeAreaMonitor())

    let isArrowHidden = try sut.inspect().find(viewWithId: "arrow").isHidden()

    XCTAssertFalse(isArrowHidden)

    ViewHosting.host(view: sut)
  }

  func test_givenFeatureTypeIsSelect_thenTextFieldDisable() throws {
    let sut = SwiftUIDropDownText(
      placeHolder: "",
      textFieldText: .constant(""),
      items: [],
      featureType: .select,
      dropDownArrowVisible: true)
      .environmentObject(SafeAreaMonitor())

    let isTextFieldDisable = try sut.inspect().find(viewWithId: "textField").isDisabled()

    XCTAssertTrue(isTextFieldDisable)

    ViewHosting.host(view: sut)
  }

  func test_givenFeatureTypeIsInput_thenTextFieldNotDisable() throws {
    let sut = SwiftUIDropDownText(
      placeHolder: "",
      textFieldText: .constant(""),
      items: [],
      featureType: .inputAssisted,
      dropDownArrowVisible: true)
      .environmentObject(SafeAreaMonitor())

    let isTextFieldDisable = try sut.inspect().find(viewWithId: "textField").isDisabled()

    XCTAssertFalse(isTextFieldDisable)

    ViewHosting.host(view: sut)
  }

  func test_givenFeatureTypeIsSelect_whenDisplayedItemOnSelect_thenDisplayedItemsAmountEqualToAllItemsAmount() throws {
    let sut = SwiftUIDropDownText(
      placeHolder: "",
      textFieldText: Binding(wrappedValue: ""),
      items: stubDatas,
      featureType: .select,
      dropDownArrowVisible: true)

    let expectation1 = sut.inspection.inspect { view in
      let textField = try view.find(viewWithId: "wholeInputView")
      try textField.callOnChange(newValue: true)

      self.publisher.send()
    }

    let expectation2 = sut.inspection.inspect(onReceive: publisher) { view in
      let candidateWordList = try view.find(viewWithId: "candidateWordList").forEach()

      try candidateWordList.first?.callOnTapGesture()

      let expect1 = try candidateWordList.first?.localizedText().string()
      let actual1 = try view.actualView().textFieldText

      XCTAssertEqual(expect1, actual1)

      let expect2 = self.stubDatas.count
      let actual2 = candidateWordList.count

      XCTAssertEqual(expect2, actual2)
    }

    ViewHosting.host(view: sut.environmentObject(SafeAreaMonitor()))

    wait(for: [expectation1, expectation2], timeout: 30)
  }

  func test_givenFeatureTypeIsInput_whenInputText_thenDisplayedItemsContainsText() throws {
    let inputWord = "中"

    let sut = SwiftUIDropDownText(
      placeHolder: "",
      textFieldText: Binding(wrappedValue: ""),
      items: stubDatas,
      featureType: .inputAssisted,
      dropDownArrowVisible: true)

    let expectation1 = sut.inspection.inspect { view in
      let textField = try view.find(viewWithId: "wholeInputView")
      try textField.callOnChange(newValue: true)

      self.publisher.send()
    }

    let expectation2 = sut.inspection.inspect(onReceive: publisher) { view in
      let entireView = try view.find(viewWithId: "entireView")
      try entireView.callOnChange(newValue: inputWord)

      self.publisher.send()
    }

    let expectation3 = sut.inspection.inspect(onReceive: publisher.dropFirst()) { view in
      let candidateWordList = try view.find(viewWithId: "candidateWordList").forEach()

      let candidateWords = try candidateWordList
        .compactMap { view in
          try view.localizedText().string()
        }

      let actual = !candidateWords
        .map { candidateWord in
          candidateWord.contains(inputWord)
        }
        .contains(false)

      XCTAssertTrue(actual)

      try candidateWordList.first?.callOnTapGesture()

      let expect1 = try candidateWordList.first?.localizedText().string()
      let actual1 = try view.actualView().textFieldText

      XCTAssertEqual(expect1, actual1)
    }

    ViewHosting.host(view: sut.environmentObject(SafeAreaMonitor()))

    wait(for: [expectation1, expectation2, expectation3], timeout: 30)
  }
}
