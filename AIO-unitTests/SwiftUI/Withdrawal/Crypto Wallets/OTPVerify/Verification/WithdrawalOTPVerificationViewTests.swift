import Mockingbird
import SharedBu
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension WithdrawalOTPVerificationView.VerificationForm: Inspecting { }

extension WithdrawalOTPVerificationViewModelProtocolMock: ObservableObject { }

final class WithdrawalOTPVerificationViewTests: XCTestCase {
  override class func tearDown() {
    super.tearDown()
    Injection.shared.registerAllDependency()
  }

  func test_givenMobileVerificationAndPlayerLocaleIsVietnam_thenInfoHintIsHighLightWithF20000_KTO_TC_191() {
    injectStubCultureCode(.VN)

    let dummyViewModel = mock(WithdrawalOTPVerificationViewModelProtocol.self)

    given(dummyViewModel.headerTitle) ~> ""
    given(dummyViewModel.sentCodeMessage) ~> ""
    given(dummyViewModel.isVerifiedFail) ~> false
    given(dummyViewModel.otpCodeLength) ~> 4

    let sut = WithdrawalOTPVerificationView<WithdrawalOTPVerificationViewModelProtocolMock>
      .VerificationForm(.constant(""), .phone)

    let exp = sut.inspection.inspect { view in
      let highLightText = try view.find(viewWithId: "HighLightText")

      let expect = ("Qua Cuộc Gọi", UIColor.redF20000)
      let actual = try highLightText.view(HighLightText.self).actualView().highlights[0]

      XCTAssertEqual(expect.0, actual.0)
      XCTAssertEqual(expect.1, actual.1)
    }

    ViewHosting.host(
      view: sut.environmentObject(dummyViewModel))

    wait(for: [exp], timeout: 30)
  }
}
