import XCTest

@testable import ktobet_asia_ios_qat

final class SwiftUIInputTextTests: XCTestCase {
  let app = XCUIApplication()

  override func setUp() {
      super.setUp()
      continueAfterFailure = false
      app.launchArguments = ["isTesting"]
      app.launchEnvironment["viewName"] = "SwiftUIInputText"
  }

  override func tearDown() {
      super.tearDown()
      app.terminate()
  }
  
  func test_whenTypeFullWidthText_InSwiftUIInputText_TextDisplayedInHalfWidth() {
      app.launch()
      let views = app.descendants(matching: .any)["SwiftUIInputText"]
      views.tap()
      let textFiled = app.descendants(matching: .textField)["SwiftUIInputText"]
      textFiled .typeText("１１１１")
    
      wait(for: 1)
      XCTAssertEqual("1111", textFiled.value as! String)
  }
}
