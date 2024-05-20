import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalOTPVerifyMethodSelectView.SelectMethodForm: Inspecting { }

extension WithdrawalOTPVerifyMethodSelectViewModelProtocolMock: ObservableObject { }

final class WithdrawalOTPVerifyMethodSelectViewTests: XCBaseTestCase {
    func test_givenMobileVerificationAvaildAndPlayerLocaleIsVietnam_thenInfoHintIsHighLightWithF20000_KTO_TC_190() {
        stubLocalizeUtils(.Vietnam())

        let dummyViewModel = mock(WithdrawalOTPVerifyMethodSelectViewModelProtocol.self)
        given(dummyViewModel.isOTPRequestInProgress) ~> false

        let sut = WithdrawalOTPVerifyMethodSelectView<WithdrawalOTPVerifyMethodSelectViewModelProtocolMock>
            .SelectMethodForm(
                Localize.string("common_otp_hint_mobile"),
                true,
                "",
                nil)

        let exp = sut.inspection.inspect { view in
            let highLightText = try view.find(viewWithId: "HighLightText")

            let expect = ("Qua Cuộc Gọi", UIColor.primaryDefault)
            let actual = try highLightText.view(HighLightText.self).actualView().highlights[0]

            XCTAssertEqual(expect.0, actual.0)
            XCTAssertEqual(expect.1, actual.1)
        }

        ViewHosting.host(
            view: sut.environmentObject(dummyViewModel))

        wait(for: [exp], timeout: 30)
    }
}
