import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension OfflinePaymentView: Inspecting { }
extension OfflinePaymentView.PickList: Inspecting { }
extension OfflinePaymentView.RemittanceInfo: Inspecting { }

extension OfflinePaymentViewModelProtocolMock: ObservableObject { }

final class OfflinePaymentViewTests: XCBaseTestCase {
  func test_whenHaveOneAvailableGateway_thenDisplayedThatGateway_KTO_TC_49() {
    let stubViewModel = mock(OfflinePaymentViewModelProtocol.self)

    given(stubViewModel.gateways) ~> [
      OfflinePaymentDataModel.Gateway(id: "1", name: "中国银行", iconName: "CNY-12")
    ]

    let sut = OfflinePaymentView<OfflinePaymentViewModelProtocolMock>.PickList(selectedGatewayId: .constant(nil))

    let exp1 = sut.inspection.inspect { view in
      let gatewayForEach = try view.find(viewWithId: "gatewayForEach")

      XCTAssertEqual(1, gatewayForEach.count)

      let gatewayName = try gatewayForEach.find(viewWithId: "gatewayName-1").localizedText().string()

      XCTAssertEqual("中国银行", gatewayName)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp1], timeout: 30)
  }

  func test_whenRemittanceLimitIs10To100_thenDisplayedRemittanceLimit10To100_KTO_TC_50() {
    let stubViewModel = mock(OfflinePaymentViewModelProtocol.self)

    given(stubViewModel.remitAmountLimitRange) ~> "10-100"
    given(stubViewModel.remitInfoErrorMessage) ~> .init(bankName: "", remitterName: "", bankCardNumber: "", amount: "")
    given(stubViewModel.remitBankList) ~> []

    let sut = OfflinePaymentView<OfflinePaymentViewModelProtocolMock>.RemittanceInfo(
      remitBankName: .constant(nil),
      remitterName: .constant(nil),
      remitBankCardNumber: .constant(nil),
      remitAmount: .constant(nil))

    let exp1 = sut.inspection.inspect { view in
      let remitAmountLimitRangeText = try view.find(viewWithId: "remitAmountLimitRange").text().string()

      XCTAssertEqual("10-100", remitAmountLimitRangeText)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [exp1], timeout: 30)
  }

  func test_whenRemitButtonDisable_thenRemitButtonDisable() {
    let stubViewModel = mock(OfflinePaymentViewModelProtocol.self)

    given(stubViewModel.submitButtonDisable) ~> true
    given(stubViewModel.fetchGatewayData()) ~> ()
    given(stubViewModel.getRemitterName()) ~> ()
    given(stubViewModel.remitterName) ~> ""
    given(stubViewModel.remitAmountLimitRange) ~> "10-100"
    given(stubViewModel.remitInfoErrorMessage) ~> .init(bankName: "", remitterName: "", bankCardNumber: "", amount: "")
    given(stubViewModel.remitBankList) ~> []
    given(stubViewModel.gateways) ~> [
      OfflinePaymentDataModel.Gateway(id: "1", name: "中国银行", iconName: "CNY-12")
    ]

    let sut = OfflinePaymentView(viewModel: stubViewModel, submitRemittanceOnClick: { _, _ in })

    let exp1 = sut.inspection.inspect { view in
      let isRemitButtonDisable = try view
        .find(viewWithId: "remitButton")
        .find(viewWithId: "asyncButton")
        .button()
        .isDisabled()

      XCTAssertTrue(isRemitButtonDisable)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor()))

    wait(for: [exp1], timeout: 30)
  }

  func test_whenRemitInfoInvalid_thenErrorMessageDisplayed() {
    let stubViewModel = mock(OfflinePaymentViewModelProtocol.self)

    given(stubViewModel.remitAmountLimitRange) ~> ""
    given(stubViewModel.remitInfoErrorMessage) ~> .init(
      bankName: "fake error message.",
      remitterName: "fake error message.",
      bankCardNumber: "fake error message.",
      amount: "fake error message.")
    given(stubViewModel.remitBankList) ~> []

    let sut = OfflinePaymentView<OfflinePaymentViewModelProtocolMock>.RemittanceInfo(
      remitBankName: .constant(nil),
      remitterName: .constant(nil),
      remitBankCardNumber: .constant(nil),
      remitAmount: .constant(nil))

    let exp1 = sut.inspection.inspect { view in
      let isRemitBankErrorTextExist = try view.find(viewWithId: "remitBankDropDownText")
        .isExist(viewWithId: "errorHint")

      let isRemitterErrorTextExist = try view.find(viewWithId: "remitterInputText")
        .isExist(viewWithId: "errorHint")

      let isRemitBankCardErrorTextExist = try view.find(viewWithId: "remitBankCardInputText")
        .isExist(viewWithId: "errorHint")

      let isRemitAmountErrorTextExit = try view.find(viewWithId: "remitAmountInputText")
        .isExist(viewWithId: "errorHint")

      XCTAssertTrue(isRemitBankErrorTextExist)
      XCTAssertTrue(isRemitterErrorTextExist)
      XCTAssertTrue(isRemitBankCardErrorTextExist)
      XCTAssertTrue(isRemitAmountErrorTextExit)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [exp1], timeout: 30)
  }

  func test_whenRemitInfoValid_thenNoErrorMessageDisplayed() {
    let stubViewModel = mock(OfflinePaymentViewModelProtocol.self)

    given(stubViewModel.remitAmountLimitRange) ~> ""
    given(stubViewModel.remitInfoErrorMessage) ~> .init(bankName: "", remitterName: "", bankCardNumber: "", amount: "")
    given(stubViewModel.remitBankList) ~> []

    let sut = OfflinePaymentView<OfflinePaymentViewModelProtocolMock>.RemittanceInfo(
      remitBankName: .constant(nil),
      remitterName: .constant(nil),
      remitBankCardNumber: .constant(nil),
      remitAmount: .constant(nil))

    let exp1 = sut.inspection.inspect { view in
      let isRemitBankErrorTextExist = try view.find(viewWithId: "remitBankDropDownText")
        .isExist(viewWithId: "ErrorHint")

      let isRemitterErrorTextExist = try view.find(viewWithId: "remitterInputText")
        .isExist(viewWithId: "ErrorHint")

      let isRemitBankCardErrorTextExist = try view.find(viewWithId: "remitBankCardInputText")
        .isExist(viewWithId: "ErrorHint")

      let isRemitAmountErrorTextExit = try view.find(viewWithId: "remitAmountInputText")
        .isExist(viewWithId: "ErrorHint")

      XCTAssertFalse(isRemitBankErrorTextExist)
      XCTAssertFalse(isRemitterErrorTextExist)
      XCTAssertFalse(isRemitBankCardErrorTextExist)
      XCTAssertFalse(isRemitAmountErrorTextExit)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(SafeAreaMonitor())
        .environmentObject(stubViewModel))

    wait(for: [exp1], timeout: 30)
  }
}
