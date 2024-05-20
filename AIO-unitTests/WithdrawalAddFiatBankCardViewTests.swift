import Combine
import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalAddFiatBankCardView.Info: Inspecting { }

final class WithdrawalAddFiatBankCardViewTests: XCBaseTestCase {
    private let publisher = PassthroughSubject<Void, Never>()

    func getStubViewModel(locale: SupportLocale) -> WithdrawalAddFiatBankCardViewModel {
        let stubPlayerConfiguration = PlayerConfigurationImpl(locale.cultureCode())
        let stubAuthenticationUseCase = mock(AuthenticationUseCase.self)
        given(stubAuthenticationUseCase.getUserName()) ~> ""
        let stubBankAppService = mock(AbsBankAppService.self)
        given(stubBankAppService.getBanks()) ~> Observable.just([]).asWrapper()
        let stubPlayerDataUseCase = mock(PlayerDataUseCase.self)
        given(stubPlayerDataUseCase.isRealNameEditable()) ~> .just(true)
        let stubAccountPatternGenerator = AccountPatternGeneratorFactory.create(stubPlayerConfiguration.supportLocale)

        let stubViewModel = WithdrawalAddFiatBankCardViewModel(
            stubPlayerConfiguration,
            stubAuthenticationUseCase,
            stubBankAppService,
            stubPlayerDataUseCase,
            stubAccountPatternGenerator,
            mock(AbsWithdrawalAppService.self))

        stubViewModel.setup()

        return stubViewModel
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
        stubLocalizeUtils(.China())
        let stubViewModel = getStubViewModel(locale: .China())

        var str = ""
        let sut = WithdrawalAddFiatBankCardView<WithdrawalAddFiatBankCardViewModel>
            .Info(tapUserName: { _ in
                str = "tapUserName"
            })

        let expectation = sut.inspection.inspect { view in
            let textField = try view
                .find(viewWithId: "usernameTextField")

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
        stubLocalizeUtils(.China())

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
        stubLocalizeUtils(.China())

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
