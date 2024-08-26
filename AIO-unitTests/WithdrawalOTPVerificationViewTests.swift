import Mockingbird
import sharedbu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

extension WithdrawalOTPVerificationView.VerificationForm: Inspecting { }

extension WithdrawalOTPVerificationViewModelProtocolMock: ObservableObject { }

final class WithdrawalOTPVerificationViewTests: XCBaseTestCase {
    func test_givenMobileVerificationAndPlayerLocaleIsVietnam_thenInfoHintIsHighLightWithF20000_KTO_TC_191() {
        stubLocalizeUtils(.Vietnam())

        let dummyViewModel = mock(WithdrawalOTPVerificationViewModelProtocol.self)

        given(dummyViewModel.headerTitle) ~> ""
        given(dummyViewModel.sentCodeMessage) ~> ""
        given(dummyViewModel.isVerifiedFail) ~> false
        given(dummyViewModel.otpCodeLength) ~> 4

        let sut = WithdrawalOTPVerificationView<WithdrawalOTPVerificationViewModelProtocolMock>
            .VerificationForm(.constant(""), .phone)

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
