import Mockingbird
import RxSwift
import sharedbu
import XCTest
@testable import ktobet_asia_ios

final class CommonVerifyOtpViewControllerTest: XCBaseTestCase {
    private var mockCommonFailed: CommonFailedTypeProtocolMock!
    private var mockDelegate: OtpViewControllerProtocolMock!
    private var validator: OtpValidatorDelegationMock!
    private var args: CommonVerifyOtpArgsBuilder!

    override func setUpWithError() throws {
        mockCommonFailed = mock(CommonFailedTypeProtocol.self)
        mockDelegate = mock(OtpViewControllerProtocol.self)
        validator = mock(OtpValidatorDelegation.self)
        given(validator.otpPattern) ~> RxSwift.Observable<OtpPattern>.just(OtpPattern.companion.create(requiredLength: 6))
        given(validator.otp) ~> RxSwift.ReplaySubject<String>.create(bufferSize: 1)
        args = CommonVerifyOtpArgsBuilder()
            .title("")
            .description("")
            .identityTip("")
            .junkTip("")
            .otpExeedSendLimitError("")
            .isHiddenCSBarItem(false)
            .isHiddenBarTitle(false)
            .commonFailedType(self.mockCommonFailed)
    }

    private func makeSUT(_ given: (CommonVerifyOtpViewController) -> Void) -> CommonVerifyOtpViewController {
        let storyboard = UIStoryboard(name: "Common", bundle: nil)
        let vc = storyboard
            .instantiateViewController(identifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        vc.delegate = mockDelegate
        given(vc)
        vc.loadViewIfNeeded()
        return vc
    }

    func test_Show_CS_BarButtonItem_When_isHiddenCSBarItem_Is_False() throws {
        let sut = makeSUT { _ in
            args.isHiddenCSBarItem(false)
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertTrue(sut.barButtonItems.contains(where: { $0.tag == customerServiceBarBtnId }))
    }

    func test_Not_Show_CS_BarButtonItem_When_isHiddenCSBarItem_Is_True() {
        let sut = makeSUT { _ in
            args.isHiddenCSBarItem(true)
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertFalse(sut.barButtonItems.contains(where: { $0.tag == customerServiceBarBtnId }))
    }

    func test_Verify_Button_Enable_When_Otp_Is_Valid() {
        let sut = makeSUT { vc in
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
            vc.validator = validator
            given(validator.isOtpValid) ~> RxSwift.Observable.just(true)
        }

        XCTAssertTrue(sut.btnVerify.isEnabled)
    }

    func test_Verify_Button_disable_When_Otp_Is_Not_Valid() {
        let sut = makeSUT { vc in
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
            vc.validator = validator
            given(validator.isOtpValid) ~> RxSwift.Observable.just(false)
        }

        XCTAssertFalse(sut.btnVerify.isEnabled)
    }

    func test_Title_Label_Text_When_Set_Title() {
        let sut = makeSUT { _ in
            args.title("Title")
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertEqual(sut.labTitle.text, "Title")
    }

    func test_Desc_Label_Text_When_Set_Description() {
        let sut = makeSUT { _ in
            args.description("Desc")
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertEqual(sut.labDesc.text, "Desc")
    }

    func test_JunkTip_Label_Text_When_Set_JunkTip() {
        let sut = makeSUT { _ in
            args.junkTip("JunkTip")
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertEqual(sut.labJunkTip.text, "JunkTip")
    }

    func test_Tip_Label_Text_When_Set_IdentityTip() {
        let sut = makeSUT { _ in
            args.identityTip("identityTip")
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }

        XCTAssertEqual(sut.labTip.text, "identityTip")
    }

    func test_Resend_Button_Enable_When_Timer_Is_Zero() {
        let sut = makeSUT { _ in
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }
        sut.setResendTimer(0)

        XCTAssertTrue(sut.btnResend.isEnabled)
    }

    func test_Resend_Button_disnable_When_Timer_Is_Ten() {
        let sut = makeSUT { _ in
            given(mockDelegate.commonVerifyOtpArgs) ~> self.args.create()
        }
        sut.setResendTimer(10)

        XCTAssertFalse(sut.btnResend.isEnabled)
    }

    class CommonVerifyOtpArgsBuilder {
        var title = ""
        var description = ""
        var identityTip = ""
        var junkTip = ""
        var otpExeedSendLimitError = ""
        var isHiddenCSBarItem = false
        var isHiddenBarTitle = false
        var commonFailedType: CommonFailedTypeProtocol = mock(CommonFailedTypeProtocol.self)

        @discardableResult
        func title(_ t: String) -> Self {
            self.title = t
            return self
        }

        @discardableResult
        func description(_ t: String) -> Self {
            self.description = t
            return self
        }

        @discardableResult
        func identityTip(_ t: String) -> Self {
            self.identityTip = t
            return self
        }

        @discardableResult
        func junkTip(_ t: String) -> Self {
            self.junkTip = t
            return self
        }

        @discardableResult
        func otpExeedSendLimitError(_ t: String) -> Self {
            self.otpExeedSendLimitError = t
            return self
        }

        @discardableResult
        func isHiddenCSBarItem(_ b: Bool) -> Self {
            self.isHiddenCSBarItem = b
            return self
        }

        @discardableResult
        func isHiddenBarTitle(_ b: Bool) -> Self {
            self.isHiddenBarTitle = b
            return self
        }

        @discardableResult
        func commonFailedType(_ c: CommonFailedTypeProtocol) -> Self {
            self.commonFailedType = c
            return self
        }

        func create() -> CommonVerifyOtpArgs {
            CommonVerifyOtpArgs(
                title: title,
                description: description,
                identityTip: identityTip,
                junkTip: junkTip,
                otpExeedSendLimitError: otpExeedSendLimitError,
                isHiddenCSBarItem: isHiddenCSBarItem,
                isHiddenBarTitle: isHiddenBarTitle,
                commonFailedType: commonFailedType)
        }
    }
}
