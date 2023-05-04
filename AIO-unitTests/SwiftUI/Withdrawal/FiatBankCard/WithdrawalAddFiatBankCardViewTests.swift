import Combine
import Mockingbird
import SharedBu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalAddFiatBankCardView.Info: Inspecting { }

final class WithdrawalAddFiatBankCardViewTests: XCTestCase {
  private let publisher = PassthroughSubject<Void, Never>()

  func getStubViewModel(locale: SupportLocale) -> WithdrawalAddFiatBankCardViewModel {
    let stubLocalRepo = mock(LocalStorageRepository.self)
    given(stubLocalRepo.getSupportLocale()) ~> locale
    let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)
    given(stubAuthenticationUseCase.getUserName()) ~> ""
    let stubBankUseCase = mock(BankUseCase.self)
    given(stubBankUseCase.getBankMap()) ~> .just([(0, Bank(bankId: 0, name: "Á Châu", shortName: "ABC"))])
    let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
    given(stubPlayerDataUseCase.isRealNameEditable()) ~> .just(true)
    let stubAccountPatternGenerator = AccountPatternGeneratorFactory.create(stubLocalRepo.getSupportLocale())

    let stubViewModel = WithdrawalAddFiatBankCardViewModel(
      stubLocalRepo,
      stubAuthenticationUseCase,
      stubBankUseCase,
      stubPlayerDataUseCase,
      stubAccountPatternGenerator,
      mock(AbsWithdrawalAppService.self))

    stubViewModel.setup()

    return stubViewModel
  }

  override func tearDown() {
    Injection.shared.registerAllDependency()
  }

  func test_addWithdrawalBank_InVNDropdownItems_ItmesDisplayBankNameWithShortName_KTO_TC_154() {
    let stubViewModel = getStubViewModel(locale: .Vietnam())

    let expect = "(ABC) Á Châu"
    let actual = stubViewModel.bankNames?.first!

    XCTAssertEqual(expect, actual)
  }

  func test_givenSelectedProvince_InCityDropdown_DisplayTheCountriesOfSelectedProvince_KTO_TC_155() {
    let stubViewModel = getStubViewModel(locale: .China())

    let sut = WithdrawalAddFiatBankCardView<WithdrawalAddFiatBankCardViewModel>.Info(tapUserName: { _ in })

    let expectation0 = sut.inspection.inspect { _ in
      stubViewModel.selectedProvince = "北京市"
      self.publisher.send()
    }

    let expectation1 = sut.inspection.inspect(onReceive: publisher) { _ in
      let expect = [
        "东城区",
        "西城区",
        "朝阳区",
        "丰台区",
        "石景山区",
        "海淀区",
        "门头沟区",
        "房山区",
        "通州区",
        "顺义区",
        "昌平区",
        "大兴区",
        "怀柔区",
        "平谷区",
        "密云县",
        "延庆县"
      ]
      let actual = stubViewModel.countries

      XCTAssertEqual(expect, actual)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [expectation0, expectation1], timeout: 10)
  }

  func test_giveBankAccountNumberPatternLengthRangeFrom10To25_InAddWithdrawalBank_accountNumerMaxLenth25_KTO_TC_156() {
    let stubViewModel = getStubViewModel(locale: .China())

    let expect = 25
    let actual = stubViewModel.accountNumberMaxLength

    XCTAssertEqual(expect, actual)
  }

  func test_tapUserName_InWithdrawalAddFiatBankCardView_IsWork() {
    injectStubCultureCode(.CN)
    let stubViewModel = getStubViewModel(locale: .China())

    var str = ""
    let sut = WithdrawalAddFiatBankCardView<WithdrawalAddFiatBankCardViewModel>
      .Info(tapUserName: { _ in
        str = "tapUserName"
      })

    let expectation = sut.inspection.inspect { view in
      let textField = try view
        .find(viewWithId: "usernameTextField")
        .find(viewWithId: "inputText")

      try textField.callOnTapGesture()

      XCTAssertEqual("tapUserName", str)
    }

    ViewHosting.host(
      view: sut
        .environmentObject(stubViewModel)
        .environmentObject(SafeAreaMonitor()))

    wait(for: [expectation], timeout: 30)
  }

  func test_givenUsernameCanEdit_InWithdrawalAddFiatBankCardViewController_AlertDisplayGoToEditUsername_KTO_TC_175() {
    injectStubCultureCode(.CN)

    let stubAlert = mock(AlertProtocol.self)
    let sut = WithdrawalAddFiatBankCardViewController.instantiate(alert: stubAlert)

    sut.loadViewIfNeeded()

    sut.editNameAction(editable: true)

    verify(
      stubAlert.show(
        any(),
        "如需要变更姓名，请前往个人设定",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }

  func test_givenUsernameCannotEdit_InWithdrawalAddFiatBankCardViewController_AlertDisplayCannotEditUsername_KTO_TC_176() {
    injectStubCultureCode(.CN)

    let stubAlert = mock(AlertProtocol.self)
    let sut = WithdrawalAddFiatBankCardViewController.instantiate(alert: stubAlert)

    sut.loadViewIfNeeded()

    sut.editNameAction(editable: false)

    verify(
      stubAlert.show(
        any(),
        "提现姓名已绑定不能变更",
        confirm: any(),
        confirmText: any(),
        cancel: any(),
        cancelText: any(),
        tintColor: any()))
      .wasCalled()
  }
}
