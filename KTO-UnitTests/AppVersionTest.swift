import sharedbu
import XCTest
@testable import ktobet_asia_ios_qat

class AppVersionTest: XCBaseTestCase {
  func testVersion() {
    test("when init Version by different constructor then two versions are equal") {
      let version1 = Version.companion.create(version: "1.9.10", code: 3)
      let version2 = Version.companion.create(version: "1.9.10+3")
      XCTAssertEqual(version1, version2)
    }
  }

  func testCompulsoryUpdate() throws {
    test("when major number increase then update action is compulsory update") {
      let current = Version.companion.create(version: "1.9.10", code: 3)
      let incoming = Version.companion.create(version: "2.0.0+4")
      let state = current.getUpdateAction(latestVersion: incoming)
      XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }

    test("when minor number increase then update action is compulsory update") {
      let current = Version.companion.create(version: "1.9.10", code: 3)
      let incoming = Version.companion.create(version: "1.10.0+4")
      let state = current.getUpdateAction(latestVersion: incoming)
      XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }

    test("when suffix is fotfix number then update action is compulsory update") {
      let current = Version.companion.create(version: "1.9.10", code: 3)
      let incoming = Version.companion.create(version: "1.9.10+5")
      let state = current.getUpdateAction(latestVersion: incoming)
      XCTAssertEqual(state, Version.UpdateAction.compulsoryupdate)
    }
  }

  func testUpToDate() {
    test("when versions are equal then update action is uptodate") {
      let current = Version.companion.create(version: "1.9.10", code: 3)
      let incoming = Version.companion.create(version: "1.9.10+3")
      let state = current.getUpdateAction(latestVersion: incoming)
      XCTAssertEqual(state, Version.UpdateAction.uptodate)
    }
  }

  func testExceeding() {
    test("when given exceeding version then update action is uptodate") {
      let current = Version.companion.create(version: "1.9.10", code: 3)
      let incoming = Version.companion.create(version: "1.9.9+2")
      let state = current.getUpdateAction(latestVersion: incoming)
      XCTAssertEqual(state, Version.UpdateAction.uptodate)
    }
  }
}
