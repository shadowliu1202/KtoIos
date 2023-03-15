import XCTest

@testable import ktobet_asia_ios_qat

final class SnackBarTests: XCTestCase {
  func test_givenSnackBarShow_thenSnackBarIsDisplayed() {
    let sut = SnackBarImpl.shared as! SnackBarImpl

    sut.show(tip: "Test1", image: nil)

    wait(for: sut.DisappearTime - 0.5)

    let actual = sut.snackBarView.frame.origin.y < UIWindow.key!.frame.size.height
    XCTAssertTrue(actual)
  }

  func test2_givenMultipleSnackBarShow_thenSnackBarThrottleIn3Seconds() {
    let sut = SnackBarImpl.shared as! SnackBarImpl

    sut.show(tip: "Test1", image: nil)
    wait(for: 1.1)

    sut.show(tip: "Test2", image: nil)
    wait(for: 1.1)

    sut.show(tip: "Test3", image: nil)
    wait(for: sut.DisappearTime - 0.5)

    let actual = sut.snackBarView.getText()
    XCTAssertEqual(actual, "Test3")
  }
}
