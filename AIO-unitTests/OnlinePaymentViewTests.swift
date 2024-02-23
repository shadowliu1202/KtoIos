import Combine
import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension OnlinePaymentView.Header: Inspecting { }
extension OnlinePaymentView.Gateways: Inspecting { }
extension OnlinePaymentView.RemittanceInfo: Inspecting { }
extension OnlinePaymentView.RemittanceButton: Inspecting { }

extension OnlinePaymentViewModelProtocolMock: ObservableObject { }

final class OnlinePaymentViewTests: XCBaseTestCase {
  private let dummyOnlinePaymentDTO = mock(PaymentsDTO.Online.self)

  private func getFakeOnlinePaymentViewModelProtocol() -> OnlinePaymentViewModelProtocolMock {
    let stubViewModel = mock(OnlinePaymentViewModelProtocol.self)
    given(stubViewModel.remitMethodName) ~> ""
    given(stubViewModel.gateways) ~> []
    given(stubViewModel.remitterName) ~> ""
    given(stubViewModel.remitInfoErrorMessage) ~> .empty
    given(stubViewModel.submitButtonDisable) ~> true

    return stubViewModel
  }

  func test_givenInputCashTypeAndRemitanceLimitRange50To100_whenInOnlinePaymentPage_thenDisplayAmountRangeHint50To100_KTO_TC_58(
  ) {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let remitTypes: [PaymentsDTO.RemitType] = [
      .normal,
      .onlyAmount,
      .fromBank,
      .directTo
    ]

    for remitType in remitTypes {
      let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
        .RemittanceInfo(
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .init(
            id: "",
            name: "",
            hint: "",
            remitType: remitType,
            remitBanks: [],
            cashType: .input(limitation: ("50", "100"), isFloatAllowed: false),
            isAccountNumberDenied: false,
            isInstructionDisplayed: false))

      let exp = sut.inspection.inspect { view in
        let amountRangeHint = try view
          .find(viewWithId: "amountRangeHint")
          .localizedText()
          .string()

        XCTAssertTrue(amountRangeHint.contains("50"))
        XCTAssertTrue(amountRangeHint.contains("100"))
      }

      ViewHosting.host(
        view: sut
          .environmentObject(dummyViewModel)
          .environmentObject(SafeAreaMonitor()))

      wait(for: [exp], timeout: 30)
    }
  }

  func test_givenOptionCashType_whenInOnlinePaymentPage_thenDisplayAmountOptionHint_KTO_TC_59() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let remitTypes: [PaymentsDTO.RemitType] = [
      .normal,
      .onlyAmount,
      .fromBank,
      .directTo
    ]

    for remitType in remitTypes {
      let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
        .RemittanceInfo(
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .init(
            id: "",
            name: "",
            hint: "",
            remitType: remitType,
            remitBanks: [],
            cashType: .option(amountList: []),
            isAccountNumberDenied: false,
            isInstructionDisplayed: false))

      let exp = sut.inspection.inspect { view in
        let amountOptionHint = try view
          .find(viewWithId: "amountOptionHint")
          .localizedText()
          .string()

        XCTAssertTrue(amountOptionHint.contains(Localize.string("deposit_amount_option_hint")))
      }

      ViewHosting.host(
        view: sut
          .environmentObject(dummyViewModel)
          .environmentObject(SafeAreaMonitor()))

      wait(for: [exp], timeout: 30)
    }
  }

  func test_givenInputCashTypeAndAllowedFloat_whenInOnlinePaymentPage_thenDisplayAmountFloatHint_KTO_TC_60() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .normal,
          remitBanks: [],
          cashType: .input(limitation: ("50", "100"), isFloatAllowed: true),
          isAccountNumberDenied: false,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let amountFloatHint = try view
        .find(viewWithId: "amountFloatHint")
        .localizedText()
        .string()

      XCTAssertTrue(amountFloatHint.contains(Localize.string("deposit_float_hint")))
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenLocaleIsVietnam_whenInOnlinePaymentPage_thenDisplayVietnameseCurrencyHint_KTO_TC_61() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .China()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        nil)

    let exp = sut.inspection.inspect { view in
      let isVNCurrencyHintHidden = try view
        .isExistByLocale(viewWithId: "vnCurrencyHint")

      XCTAssertFalse(isVNCurrencyHintHidden)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenInputCashTypeAndRemitanceLimitRange50To100_whenRemitanceOverRange_thenDisplayErrorHint_KTO_TC_62() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.remitInfoErrorMessage)
      ~> .init(
        remitterName: "",
        remitterAccountNumber: "",
        remitAmount: "Out of range.")

    let remitTypes: [PaymentsDTO.RemitType] = [
      .normal,
      .onlyAmount,
      .fromBank,
      .directTo
    ]

    for remitType in remitTypes {
      let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
        .RemittanceInfo(
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .init(
            id: "",
            name: "",
            hint: "",
            remitType: remitType,
            remitBanks: [],
            cashType: .input(limitation: ("50", "100"), isFloatAllowed: false),
            isAccountNumberDenied: false,
            isInstructionDisplayed: false))

      let exp = sut.inspection.inspect { view in
        let amountTextFieldInput = try view
          .find(viewWithId: "textFieldInputAmount")
        let isAmountErrorHintDisplay = amountTextFieldInput
          .isExist(viewWithId: "errorHint")

        XCTAssertTrue(isAmountErrorHintDisplay)
      }

      ViewHosting.host(
        view: sut
          .environmentObject(stubViewModel)
          .environmentObject(SafeAreaMonitor()))

      wait(for: [exp], timeout: 30)
    }
  }

  func test_givenOptionCashTypeAndRemitanceLimitRange50To100_whenRemitanceOverRange_thenDisplayErrorHint_KTO_TC_63() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.remitInfoErrorMessage)
      ~> .init(
        remitterName: "",
        remitterAccountNumber: "",
        remitAmount: "Out of range.")

    let remitTypes: [PaymentsDTO.RemitType] = [
      .normal,
      .onlyAmount,
      .fromBank,
      .directTo
    ]

    for remitType in remitTypes {
      let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
        .RemittanceInfo(
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .constant(nil),
          .init(
            id: "",
            name: "",
            hint: "",
            remitType: remitType,
            remitBanks: [],
            cashType: .option(amountList: []),
            isAccountNumberDenied: false,
            isInstructionDisplayed: false))

      let exp = sut.inspection.inspect { view in
        let amountTextFieldOption = try view
          .find(viewWithId: "textFieldOptionAmount")
        let isAmountErrorHintDisplay = amountTextFieldOption
          .isExist(viewWithId: "errorHint")

        XCTAssertTrue(isAmountErrorHintDisplay)
      }

      ViewHosting.host(
        view: sut
          .environmentObject(stubViewModel)
          .environmentObject(SafeAreaMonitor()))

      wait(for: [exp], timeout: 30)
    }
  }

  func test_givenGatewayNeedDisplayInstructions_whenInOnlinePaymentPage_thenDisplayInstructionsLink_KTO_TC_66() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .Header(
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .normal,
          remitBanks: [],
          cashType: .option(amountList: []),
          isAccountNumberDenied: false,
          isInstructionDisplayed: true),
        { })

    let exp = sut.inspection.inspect { view in
      let isInstructionDisplay = try view
        .isExistByVisibility(viewWithId: "instructionLink")

      XCTAssertTrue(isInstructionDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenPlayerHasOneGateway_whenInOnlinePaymentPage_thenShowOneGateway_KTO_TC_67() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.gateways) ~> [
      .init(
        id: "",
        name: "",
        hint: "",
        remitType: .normal,
        remitBanks: [],
        cashType: .option(amountList: []),
        isAccountNumberDenied: true,
        isInstructionDisplayed: true)
    ]

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .Gateways(.constant(nil))

    let exp = sut.inspection.inspect { view in
      let gatewayCellAmount = try view
        .find(viewWithId: "gatewayCells")
        .forEach()
        .count

      XCTAssertEqual(1, gatewayCellAmount)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenGatewayRemitTypeIsNormal_whenInOnlinePaymentPage_thenDisplayNormalForm_KTO_TC_69() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .normal,
          remitBanks: [],
          cashType: .option(amountList: []),
          isAccountNumberDenied: false,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let isNormalFormDisplay = view
        .isExist(viewWithId: "normalForm")

      XCTAssertTrue(isNormalFormDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenGatewayRemitTypeIsNormalAndDontNeedAccountNumber_whenInOnlinePaymentPage_thenNotDisplayAccountTextFeild_KTO_TC_70(
  ) {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .normal,
          remitBanks: [],
          cashType: .option(amountList: ["100"]),
          isAccountNumberDenied: true,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let isAccountNumberDisplay = try view
        .isExistByVisibility(viewWithId: "textFieldAccountNumber")

      XCTAssertFalse(isAccountNumberDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenGatewayRemitTypeIsFromBank_whenInOnlinePaymentPage_thenDisplayBankListTextField_KTO_TC_73() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .fromBank,
          remitBanks: [],
          cashType: .option(amountList: []),
          isAccountNumberDenied: true,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let isBankListDisplay = view
        .isExist(viewWithId: "textFieldBankList")

      XCTAssertTrue(isBankListDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenGatewayRemitTypeIsDirectTo_whenInOnlinePaymentPage_thenDisplayBankListTextField_KTO_TC_76() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .directTo,
          remitBanks: [],
          cashType: .option(amountList: []),
          isAccountNumberDenied: true,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let isBankListDisplay = view
        .isExist(viewWithId: "textFieldBankList")

      XCTAssertTrue(isBankListDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenGatewayRemitTypeIsOnlyAmount_whenInOnlinePaymentPage_thenDisplayOnlyAmountForm_KTO_TC_79() {
    let dummyViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(dummyViewModel.getSupportLocale()) ~> .Vietnam()

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceInfo(
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .constant(nil),
        .init(
          id: "",
          name: "",
          hint: "",
          remitType: .onlyAmount,
          remitBanks: [],
          cashType: .option(amountList: []),
          isAccountNumberDenied: false,
          isInstructionDisplayed: false))

    let exp = sut.inspection.inspect { view in
      let isOnlyAmountFormDisplay = view
        .isExist(viewWithId: "onlyAmountForm")

      XCTAssertTrue(isOnlyAmountFormDisplay)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(dummyViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenVaildRemittanceInfo_whenInOnlinePaymentPage_thenSubmitButtonEnable_KTO_TC_86() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.submitButtonDisable) ~> false

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceButton(
        nil,
        nil,
        nil,
        nil,
        nil,
        { _ in })

    let exp = sut.inspection.inspect { view in
      let isRemitButtonDisable = try view
        .find(viewWithId: "remittanceButton")
        .find(viewWithId: "asyncButton")
        .button()
        .isDisabled()

      XCTAssertFalse(isRemitButtonDisable)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }

  func test_givenInvaildRemittanceInfo_whenInOnlinePaymentPage_thenSubmitButtonDisable_KTO_TC_87() {
    let stubViewModel = getFakeOnlinePaymentViewModelProtocol()
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.submitButtonDisable) ~> true

    let sut = OnlinePaymentView<OnlinePaymentViewModelProtocolMock>
      .RemittanceButton(
        nil,
        nil,
        nil,
        nil,
        nil,
        { _ in })

    let exp = sut.inspection.inspect { view in
      let isRemitButtonDisable = try view
        .find(viewWithId: "remittanceButton")
        .find(viewWithId: "asyncButton")
        .button()
        .isDisabled()

      XCTAssertTrue(isRemitButtonDisable)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp], timeout: 30)
  }
}
