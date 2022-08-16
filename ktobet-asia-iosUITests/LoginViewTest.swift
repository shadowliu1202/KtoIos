import XCTest
import SwiftUI

@testable import ktobet_asia_ios_qat
class LoginViewTest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["isUITesting"]
        app.launchEnvironment["viewName"] = "LoginView"
    }

    override func tearDownWithError() throws {

    }

    func testExample() throws {
        app.launch()
        let views = app.descendants(matching: .any)
        let captcha = views["captcha"]
        XCTAssertTrue(captcha.exists)
    }
}
