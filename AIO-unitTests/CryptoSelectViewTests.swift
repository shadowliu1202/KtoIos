import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension CryptoSelectView: Inspecting { }
extension CryptoSelectView.Header: Inspecting { }
extension CryptoSelectView.SelectorList: Inspecting { }

final class CryptoSelectViewTests: XCBaseTestCase {
  func test_TapTutorialBtn_InCryptoSelectView_CallbackFunctionIsCalled() {
    var str = ""
    let sut = CryptoSelectView<CryptoDepositViewModelProtocolMock>.Header(
      locale: .Vietnam(),
      userGuideOnTap: { },
      tutorialOnTap: {
        str = "tutorialOnTap"
      })

    let expectation = sut.inspection.inspect { view in
      let tutorial = try view
        .find(viewWithId: "tutorial")
        .view(LocalizeFont<Text>.self)
      try tutorial.callOnTapGesture()

      XCTAssertEqual("tutorialOnTap", str)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_AtVNEnviroment_InCryptoSelectorPage_VideoTutorialBtnIsDisplayed_KTO_TC_41() {
    let sut = CryptoSelectView<CryptoDepositViewModelProtocolMock>.Header(
      locale: .Vietnam(),
      userGuideOnTap: { },
      tutorialOnTap: { })

    let expectation = sut.inspection.inspect { view in
      let tutorial = try view
        .find(viewWithId: "tutorial")
        .view(LocalizeFont<Text>.self)

      XCTAssertNotNil(tutorial)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_AtCNEnvironment_InCryptoSelectorPage_VideoTutorialBtnIsNotDisplayed_KTO_TC_42() {
    let sut = CryptoSelectView<CryptoDepositViewModelProtocolMock>.Header(
      locale: .China(),
      userGuideOnTap: { },
      tutorialOnTap: { })

    let expectation = sut.inspection.inspect { view in
      let isTutorialExist = try view
        .isExistByLocale(viewWithId: "tutorial")

      XCTAssertFalse(isTutorialExist)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_TapCryptoGuideText_InCryptoSelectView_CallbackFunctionIsCalled() {
    var str = ""
    let sut = CryptoSelectView<CryptoDepositViewModelProtocolMock>.Header(
      locale: .Vietnam(),
      userGuideOnTap: {
        str = "userGuideOnTap"
      },
      tutorialOnTap: { })

    let expectation = sut.inspection.inspect { view in
      let tutorial = try view
        .find(viewWithId: "userGuide")
        .hStack()
      try tutorial.callOnTapGesture()

      XCTAssertEqual("userGuideOnTap", str)
    }

    ViewHosting.host(view: sut)

    wait(for: [expectation], timeout: 30)
  }

  func test_HasOneCryptoOption_InCryptoSelectView_OneCryptoOptionIsDisplayed() {
    let stubViewModel = mock(CryptoDepositViewModelProtocol.self)
    given(stubViewModel.options) ~> [
      .init(with: PaymentsDTO.TypeOptions(optionsId: "", name: "", promotion: "", cryptoType: .usdt), icon: "", isSelected: true)
    ]

    let sut = CryptoSelectView<CryptoDepositViewModelProtocolMock>.SelectorList()

    let expectation = sut.inspection.inspect { view in
      let numberOfRows = try view
        .find(viewWithId: "selectorRows")
        .forEach()
        .count

      XCTAssertEqual(1, numberOfRows)
    }

    ViewHosting.host(
      view: sut.environmentObject(stubViewModel))

    wait(for: [expectation], timeout: 3)
  }
}
