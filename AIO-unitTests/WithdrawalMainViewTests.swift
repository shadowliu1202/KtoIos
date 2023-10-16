import Combine
import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalMainView.Instruction: Inspecting { }
extension WithdrawalMainView.Methods: Inspecting { }

extension WithdrawalMainViewModelProtocolMock: ObservableObject { }

final class WithdrawalMainViewTests: XCBaseTestCase {
  private func getFakeWithdrawalMainViewModelProtocol() -> WithdrawalMainViewModelProtocolMock {
    let fakeViewModel = mock(WithdrawalMainViewModelProtocol.self)

    given(fakeViewModel.instruction) ~> nil
    given(fakeViewModel.recentRecords) ~> nil
    given(fakeViewModel.enableWithdrawal) ~> false
    given(fakeViewModel.allowedWithdrawalFiat) ~> nil
    given(fakeViewModel.allowedWithdrawalCrypto) ~> nil
    given(fakeViewModel.setupData()) ~> { }

    return fakeViewModel
  }

  func test_whenInWithdrawalMainPage_thenDisplayDailyAmountLimitAndDailyCountLimit_KTO_TC_3() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()
    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Instruction({ }, { })

    given(stubViewModel.instruction) ~> .init(
      dailyAmountLimit: "1,000",
      dailyMaxCount: "99",
      turnoverRequirement: nil,
      cryptoWithdrawalRequirement: nil)

    let exp = sut.inspection.inspect { view in
      let dailyAmountLimitText = try view.find(viewWithId: "dailyAmountLimit")
        .localizedText()
        .string()

      let dailyCountLimitText = try view.find(viewWithId: "dailyCountLimit")
        .localizedText()
        .string()

      XCTAssertTrue(
        dailyAmountLimitText
          .contains(Localize.string(
            "withdrawal_daily_limit_widthrawal_amount", "1,000")))

      XCTAssertTrue(
        dailyCountLimitText
          .contains(Localize.string(
            "withdrawal_daily_limit_widthrawal_times", "99")))
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }

  func test_givenPlayerHasCryptoTurnover_whenInWithdrawalMainPage_thenDisplayCryptoRequirementAmount_KTO_TC_4() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()
    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Instruction({ }, { })

    given(stubViewModel.instruction) ~> .init(
      dailyAmountLimit: "",
      dailyMaxCount: "",
      turnoverRequirement: nil,
      cryptoWithdrawalRequirement: ("200", "CNY"))

    let exp = sut.inspection.inspect { view in
      let cryptoRequirementAmountText = try view.find(viewWithId: "cryptoRequirementAmount")
        .localizedText()
        .string()

      XCTAssertTrue(
        cryptoRequirementAmountText
          .contains(Localize.string("common_requirement", "200")))
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }

  func test_givenPlayerHasNoCrpytoTurnover_whenInWithdrawalMainPage_thenDisplayCryptoRequirementNone_KTO_TC_5() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()
    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Instruction()

    given(stubViewModel.instruction) ~> .init(
      dailyAmountLimit: "",
      dailyMaxCount: "",
      turnoverRequirement: nil,
      cryptoWithdrawalRequirement: nil)

    let exp = sut.inspection.inspect { view in
      let isCryptoRequirementNoneTextExist = view.isExist(viewWithId: "cryptoRequirementNone")

      let isCryptoRequirementAmountTextExist = view
        .isExist(viewWithId: "cryptoRequirementAmount")

      XCTAssertTrue(isCryptoRequirementNoneTextExist)
      XCTAssertFalse(isCryptoRequirementAmountTextExist)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }

  func test_givenNoAnyWithdrawalQuota_whenInWithdrawalMainPage_thenWithdrawalMethodsAreDisable_KTO_TC_8() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()

    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Methods()

    given(stubViewModel.enableWithdrawal) ~> false

    let exp = sut.inspection.inspect { view in
      let methods = try view.find(viewWithId: "methods")

      XCTAssertTrue(methods.isDisabled())
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }

  func test_givenHasCryptoTurnOver_whenTapFiatWithdrawal_thenShowAlert_KTO_TC_9() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()
    let mockAlert = mock(AlertProtocol.self)

    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Methods(
      { },
      {
        mockAlert.show(
          Localize.string("cps_cash_withdrawal_lock_title"),
          Localize.string("cps_cash_withdrawal_lock_desc", "1,000CNY"),
          confirm: { },
          cancel: nil)
      },
      { },
      { })

    given(stubViewModel.instruction) ~> .init(
      dailyAmountLimit: "",
      dailyMaxCount: "",
      turnoverRequirement: "1,000",
      cryptoWithdrawalRequirement: nil)

    given(stubViewModel.enableWithdrawal) ~> true
    given(stubViewModel.allowedWithdrawalFiat) ~> false

    let exp = sut.inspection.inspect { view in
      let methodFiat = try view
        .find(viewWithId: "methodFiat")

      try methodFiat.callOnTapGesture()

      verify(mockAlert.show(
        Localize.string("cps_cash_withdrawal_lock_title"),
        Localize.string("cps_cash_withdrawal_lock_desc", "1,000CNY"),
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
        .wasCalled()
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }

  func test_givenPlayerIsNotValidForCryptoWithdrawal_whenTapCryptoWithdrawal_thenShowAlert_KTO_TC_57() {
    let stubViewModel = getFakeWithdrawalMainViewModelProtocol()
    let mockAlert = mock(AlertProtocol.self)

    let sut = WithdrawalMainView<WithdrawalMainViewModelProtocolMock>.Methods(
      { },
      { },
      { },
      {
        mockAlert.show(
          nil,
          Localize.string("cps_withdrawal_all_fiat_first"),
          confirm: { },
          cancel: nil)
      })

    given(stubViewModel.enableWithdrawal) ~> true
    given(stubViewModel.allowedWithdrawalCrypto) ~> false

    let exp = sut.inspection.inspect { view in
      let methodCrypto = try view
        .find(viewWithId: "methodCrypto")

      try methodCrypto.callOnTapGesture()

      verify(mockAlert.show(
        any(),
        Localize.string("cps_withdrawal_all_fiat_first"),
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
        .wasCalled()
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel))

    wait(for: [exp], timeout: 30)
  }
}
