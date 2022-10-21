import XCTest

@testable import ktobet_asia_ios_qat

final class PasteableTextFieldTest: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["isUITesting"]
        app.launchEnvironment["viewName"] = "PasteableTextField"
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    func test_giveTextFieldDisablePaste_whenLongPressTextField_thanShouldNotShowPastePopup() throws {
        let views = app.descendants(matching: .any)
        let textFiled = views["PasteableTextField"]
        XCTAssertTrue(textFiled.exists)
        textFiled.tap()
        textFiled.typeText("1234")
        XCTAssertEqual(textFiled.value as! String, "1234")
        textFiled.press(forDuration: 0.5)
        let collectionViewsQuery = app.collectionViews
        let selectAll = collectionViewsQuery.staticTexts["Select All"]
        wait(for: 3)
        selectAll.tap()
        let cut = collectionViewsQuery.staticTexts["Cut"]
        wait(for: 3)
        cut.tap()
        XCTAssertEqual(textFiled.value as! String, "")
        textFiled.press(forDuration: 0.8)
        let paste = collectionViewsQuery.staticTexts["Paste"]
        wait(for: 1)
        XCTAssertFalse(paste.exists)
    }
    
}
