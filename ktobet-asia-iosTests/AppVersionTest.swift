import XCTest
import SharedBu
@testable import ktobet_asia_ios_qat

class AppVersionTest: XCTestCase {
    var current: Version!
    
    func testMajorCompulsoryupdate() throws {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "2.0.0")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }
    
    func testMinorCompulsoryupdate() throws {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.10.0")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }
    
    func testHotfixCompulsoryupdate() throws {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.9.10+5")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }
    
    func testOptionalUpdate() {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.9.11")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.optionalupdate)
    }
    
    func testOptionalUpdateWithSuffix() {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.9.11+20")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.optionalupdate)
    }
    
    func testUpToDate() {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.9.10")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.uptodate)
    }
    
    func testUpToDateWithSuffix() {
        let current = Version.companion.create(version: "1.9.10", code: 3)
        let incoming = Version.companion.create(version: "1.9.10+3")
        let state = current.getUpdateAction(latestVersion: incoming)
        XCTAssertEqual(state, Version.UpdateAction.uptodate)
    }
}

