import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

import XCTest

final class SignupUserinfoViewControllerTests: XCTestCase {
  func test_givenErrorKtoPlayerRegisterBlock_whenRegister_thenShowAlert() {
    let mockAlert = mock(AlertProtocol.self)
    Alert.shared = mockAlert
    
    let sut = SignupUserinfoViewController.initFrom(storyboard: "Signup")
    
    sut.handleErrors(KtoPlayerRegisterBlock())
    
    verify(mockAlert.show(
      Localize.string("common_tip_title_warm"),
      Localize.string("register_step2_unusual_activity"),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled()
  }
}
