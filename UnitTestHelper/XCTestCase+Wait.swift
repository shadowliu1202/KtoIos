import XCTest

@testable import ktobet_asia_ios_qat

extension XCTestCase {
  func wait(for duration: TimeInterval) {
    let waitExpectation = expectation(description: "Waiting")
    let when = DispatchTime.now() + duration
    DispatchQueue.main.asyncAfter(deadline: when) {
      waitExpectation.fulfill()
    }
    waitForExpectations(timeout: duration + 10)
  }
}
