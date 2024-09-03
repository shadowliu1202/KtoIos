import sharedbu
import XCTest

@testable import ktobet_asia_ios

class DateExtensionTest: XCBaseTestCase {
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

        let actualLocalDateTime = sharedbu.LocalDateTime(
            year: 2022,
            month: sharedbu.Month.june,
            dayOfMonth: 7,
            hour: 12,
            minute: 0,
            second: 0,
            nanosecond: 0)
        let actualTimeZone = sharedbu.TimeZone.companion.of(zoneId: timeZoneID)
        let offsetDateTime = sharedbu.OffsetDateTime(localDateTime: actualLocalDateTime, timeZone: actualTimeZone)

        let actual: Date = offsetDateTime.convertToDate()

        XCTAssertEqual(expect, actual)
    }

    func testsharedbuTimeZoneToFoundation() {
        let timeZoneID = "Asia/Taipei"

        let expect = Foundation.TimeZone(identifier: timeZoneID)
        let sharedBuTimeZone = sharedbu.TimeZone.companion.of(zoneId: timeZoneID)

        let actual = sharedBuTimeZone.toFoundation()

        XCTAssertEqual(expect, actual)
    }

    func testsharedbuTimeZoneFromFoundation() {
        let timeZoneID = "Asia/Taipei"

        let expect = sharedbu.TimeZone.companion.of(zoneId: timeZoneID)
        let foundationTimeZone = Foundation.TimeZone(identifier: timeZoneID)!

        let actual = sharedbu.TimeZone.fromFoundation(foundationTimeZone)

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
        let localDateTime = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 15,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)

        let expect = sharedbu.OffsetDateTime.companion.create(localDateTime: localDateTime, zoneId: "UTC+0")
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
        let localDateTime1 = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 15,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)

        let expect1 = sharedbu.OffsetDateTime.companion.create(localDateTime: localDateTime1, zoneId: "UTC+0")
        let actual1 = now1.toUTCOffsetDateTime()

        XCTAssertEqual(expect1, actual1)
    }
  
    func testToLocalDateTime() {
        let dateComponent = DateComponents(timeZone: .init(secondsFromGMT: 0)!, year: 2023, month: 6, day: 15, hour: 23)
        let date = Calendar.current.date(from: dateComponent)!
    
        let actual = date.toLocalDateTime(Foundation.TimeZone(identifier: "Asia/Taipei")!)
    
        let expect = sharedbu.LocalDateTime(
            year: 2023,
            month: .june,
            dayOfMonth: 16,
            hour: 7,
            minute: 0,
            second: 0,
            nanosecond: 0)
    
        XCTAssertEqual(expect, actual)
    }
  
    func testToLocalDate() {
        let dateComponent = DateComponents(timeZone: .init(secondsFromGMT: 0)!, year: 2023, month: 6, day: 15, hour: 23)
        let date = Calendar.current.date(from: dateComponent)!
    
        let actual = date.toLocalDate(Foundation.TimeZone(identifier: "Asia/Taipei")!)
    
        let expect = sharedbu.LocalDate(year: 2023, month: .june, dayOfMonth: 16)
    
        XCTAssertEqual(expect, actual)
    }
}
