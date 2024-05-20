import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

class StringExtensionTest: XCBaseTestCase {
    func testToLocalDateTime() {
        let apiReturnDate = "2022-06-10T00:00:00+08:00"

        let expect = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 9,
            hour: 23,
            minute: 0,
            second: 0,
            nanosecond: 0)
        let actual = try! apiReturnDate.toKotlinLocalDateTime(timeZone: TimeZone(identifier: "Asia/Saigon")!)

        XCTAssertEqual(expect, actual)

        let expect1 = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 10,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)
        let actual1 = try! apiReturnDate.toKotlinLocalDateTime(timeZone: TimeZone(identifier: "Asia/Taipei")!)

        XCTAssertEqual(expect1, actual1)
    }

    func testToLocalDateTimeWithAccountTimeZone() {
        let apiReturnDate = "2022-06-10"

        let expect = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 10,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)
        let actual = try! apiReturnDate.toLocalDateTimeWithAccountTimeZone()

        XCTAssertEqual(expect, actual)

        let apiReturnDate1 = "2022/06/10"

        let expect1 = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 10,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)
        let actual1 = try! apiReturnDate1.toLocalDateTimeWithAccountTimeZone()

        XCTAssertEqual(expect1, actual1)
    }

    func testToLocalDate() {
        let apiReturnDate = "2022-06-10T00:00:00+08:00"

        let expect = sharedbu.LocalDate(year: 2022, monthNumber: 6, dayOfMonth: 9)
        let actual = try! apiReturnDate.toKotlinLocalDate(timeZone: TimeZone(identifier: "Asia/Saigon")!)

        XCTAssertEqual(expect, actual)

        let expect1 = sharedbu.LocalDate(year: 2022, monthNumber: 6, dayOfMonth: 10)
        let actual1 = try! apiReturnDate.toKotlinLocalDate(timeZone: TimeZone(identifier: "Asia/Taipei")!)

        XCTAssertEqual(expect1, actual1)
    }

    func testToLocalDateWithAccountTimeZone() {
        let apiReturnDate = "2022-06-10"

        let expect = sharedbu.LocalDate(year: 2022, monthNumber: 6, dayOfMonth: 10)
        let actual = try! apiReturnDate.toLocalDateWithAccountTimeZone()

        XCTAssertEqual(expect, actual)

        let apiReturnDate1 = "2022/06/10"

        let expect1 = sharedbu.LocalDate(year: 2022, monthNumber: 6, dayOfMonth: 10)
        let actual1 = try! apiReturnDate1.toLocalDateWithAccountTimeZone()

        XCTAssertEqual(expect1, actual1)
    }

    func testToOffsetDateTime() {
        let apiReturnDate = "2022-06-10T00:00:00+08:00"
        let timeZone = TimeZone(identifier: "Asia/Taipei")!
        let localDateTime = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 10,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)

        let expect = sharedbu.OffsetDateTime.companion.create(localDateTime: localDateTime, zoneId: timeZone.identifier)
        let actual = try! apiReturnDate.toOffsetDateTime()

        XCTAssertEqual(expect.epochSeconds, actual.epochSeconds)
    }

    func testToOffsetDateTimeWithAccountTimeZone() {
        let apiReturnDate = "2022-06-10"
        let timeZone = TimeZone(identifier: "Asia/Taipei")!
        let localDateTime = sharedbu.LocalDateTime(
            year: 2022,
            monthNumber: 6,
            dayOfMonth: 10,
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: 0)

        let expect = sharedbu.OffsetDateTime.companion.create(localDateTime: localDateTime, zoneId: timeZone.identifier)
        let actual = try! apiReturnDate.toOffsetDateTimeWithAccountTimeZone(timeZone: timeZone)

        XCTAssertEqual(expect.epochSeconds, actual.epochSeconds)
    }

    func testToDate() {
        let taipeiDate = "06/10/2022 08:00:00"
        let dateFormat = "MM/dd/yyyy HH:mm:ss"
        let timeZone = TimeZone(identifier: "Asia/Taipei")!

        let expect = DateComponents(
            calendar: .current,
            timeZone: timeZone,
            year: 2022,
            month: 6,
            day: 10,
            hour: 8,
            minute: 0,
            second: 0).date
        let actual = taipeiDate.toDate(format: dateFormat, timeZone: timeZone)

        XCTAssertEqual(expect, actual)
    }

    func testBranchName() throws {
        // chinese and english
        XCTAssertTrue("branchName".isValidRegex(format: .branchName), "英文可以")
        XCTAssertTrue("中文".isValidRegex(format: .branchName), "中文可以")
        XCTAssertFalse("2k".isValidRegex(format: .branchName), "數字不行")
        XCTAssertFalse("".isValidRegex(format: .branchName), "空白不行")
        XCTAssertFalse("qwertyuiopasdfghjklzxcvbnmqwertyuiop".isValidRegex(format: .branchName), "長度不超過31")
    }

    func testFullWidthToHalfWidth() {
        let text = "１１１１"
        let actual = text.halfWidth

        XCTAssertEqual("1111", actual)
    }
}
