import sharedbu
import XCTest
@testable import ktobet_asia_ios_qat

class AppVersionTest: XCBaseTestCase {
    func testVersion() {
        test("when init Version by different constructor then two versions are equal") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "1.9.10+3", link: "", size: 0.0)
            XCTAssertEqual(.upToDate, current.getUpdateAction(latestVersion: online))
        }
    }

    func testCompulsoryUpdate() throws {
        test("when major number increase then update action is compulsory update") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "2.0.0+4", link: "", size: 0.0)
            XCTAssertEqual(.compulsoryUpdate, current.getUpdateAction(latestVersion: online))
        }

        test("when minor number increase then update action is compulsory update") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "1.10.0+4", link: "", size: 0.0)
            XCTAssertEqual(.compulsoryUpdate, current.getUpdateAction(latestVersion: online))
        }

        test("when suffix is fotfix number then update action is compulsory update") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "1.9.10+5", link: "", size: 0.0)
            XCTAssertEqual(.compulsoryUpdate, current.getUpdateAction(latestVersion: online))
        }
    }

    func testUpToDate() {
        test("when versions are equal then update action is uptodate") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "1.9.10+3", link: "", size: 0.0)
            XCTAssertEqual(.upToDate, current.getUpdateAction(latestVersion: online))
        }
    }

    func testExceeding() {
        test("when given exceeding version then update action is uptodate") {
            let current = LocalVersion.companion.create(version: "1.9.10", bundleVersion: "3")
            let online = OnlineVersion.companion.create(version: "1.9.9+2", link: "", size: 0.0)
            XCTAssertEqual(.upToDate, current.getUpdateAction(latestVersion: online))
        }
    }
}
