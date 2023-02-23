import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

class DateExtensionTest: XCTestCase {
  func testOffsetDateTimeToDate() {
    let timeZoneID = "Asia/Taipei"

    let expect = DateComponents(
      calendar: .current,
      timeZone: Foundation.TimeZone(identifier: timeZoneID),
      year: 2022,
      month: 6,
      day: 7,
      hour: 12,
      minute: 0,
      second: 0).date

    let actualLocalDateTime = SharedBu.LocalDateTime(
      year: 2022,
      month: SharedBu.Month.june,
      dayOfMonth: 7,
      hour: 12,
      minute: 0,
      second: 0,
      nanosecond: 0)
    let actualTimeZone = SharedBu.TimeZone.companion.of(zoneId: timeZoneID)
    let offsetDateTime = SharedBu.OffsetDateTime(localDateTime: actualLocalDateTime, timeZone: actualTimeZone)

    let actual: Date = offsetDateTime.convertToDate()

    XCTAssertEqual(expect, actual)
  }

  func testSharedBuTimeZoneToFoundation() {
    let timeZoneID = "Asia/Taipei"

    let expect = Foundation.TimeZone(identifier: timeZoneID)
    let sharedBuTimeZone = SharedBu.TimeZone.companion.of(zoneId: timeZoneID)

    let actual = sharedBuTimeZone.toFoundation()

    XCTAssertEqual(expect, actual)
  }

  func testSharedBuTimeZoneFromFoundation() {
    let timeZoneID = "Asia/Taipei"

    let expect = SharedBu.TimeZone.companion.of(zoneId: timeZoneID)
    let foundationTimeZone = Foundation.TimeZone(identifier: timeZoneID)!

    let actual = SharedBu.TimeZone.fromFoundation(foundationTimeZone)

    XCTAssertEqual(expect, actual)
  }

  func testToUTCOffsetDateTime() {
    let timeZoneID = "UTC+0"
    let now = DateComponents(
      calendar: .current,
      timeZone: Foundation.TimeZone(identifier: timeZoneID),
      year: 2022,
      month: 6,
      day: 15,
      hour: 0,
      minute: 0,
      second: 0,
      nanosecond: 0).date!
    let localDateTime = SharedBu.LocalDateTime(
      year: 2022,
      monthNumber: 6,
      dayOfMonth: 15,
      hour: 0,
      minute: 0,
      second: 0,
      nanosecond: 0)

    let expect = SharedBu.OffsetDateTime.companion.create(localDateTime: localDateTime, zoneId: "UTC+0")
    let actual = now.toUTCOffsetDateTime()

    XCTAssertEqual(expect, actual)

    let timeZoneID1 = "Asia/Taipei"
    let now1 = DateComponents(
      calendar: .current,
      timeZone: Foundation.TimeZone(identifier: timeZoneID1),
      year: 2022,
      month: 6,
      day: 15,
      hour: 8,
      minute: 0,
      second: 0,
      nanosecond: 0).date!
    let localDateTime1 = SharedBu.LocalDateTime(
      year: 2022,
      monthNumber: 6,
      dayOfMonth: 15,
      hour: 0,
      minute: 0,
      second: 0,
      nanosecond: 0)

    let expect1 = SharedBu.OffsetDateTime.companion.create(localDateTime: localDateTime1, zoneId: "UTC+0")
    let actual1 = now1.toUTCOffsetDateTime()

    XCTAssertEqual(expect1, actual1)
  }
}
