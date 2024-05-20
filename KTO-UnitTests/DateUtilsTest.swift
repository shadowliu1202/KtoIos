import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

class DateUtilsTest: XCBaseTestCase {
    func testParseOffsetDate() throws {
        let apiReturnDate = "2022-06-10T00:00:00+08:00"
        let timeZone = TimeZone(identifier: "Asia/Taipei")!

        let expect = DateComponents(
            calendar: .current,
            timeZone: timeZone,
            year: 2022,
            month: 6,
            day: 10,
            hour: 0,
            minute: 0,
            second: 0).date!
        let actual = try DateUtils.parseOffsetDate(string: apiReturnDate)

        XCTAssertNoThrow(actual)
        XCTAssertEqual(expect, actual)

        let apiReturnDate1 = "2022-06-10T00:00:00.1230000+07:00"
        let actual1 = try DateUtils.parseOffsetDate(string: apiReturnDate1)

        XCTAssertNoThrow(actual1)

        let apiReturnDate2 = "2022-06-10T00:00:00"
        let actual2 = {
            try DateUtils.parseOffsetDate(string: apiReturnDate2)
        }

        XCTAssertThrowsError(try actual2())

        let apiReturnDate3 = "2022-06-10"
        let actual3 = {
            try DateUtils.parseOffsetDate(string: apiReturnDate3)
        }

        XCTAssertThrowsError(try actual3())

        let apiReturnDate4 = "2022/06/10"
        let actual4 = {
            try DateUtils.parseOffsetDate(string: apiReturnDate4)
        }

        XCTAssertThrowsError(try actual4())
    }

    func testParseLocalDate() throws {
        let apiReturnDate = "2022-06-10"
        let timeZone = TimeZone(identifier: "Asia/Taipei")!

        let expect = DateComponents(
            calendar: .current,
            timeZone: timeZone,
            year: 2022,
            month: 6,
            day: 10,
            hour: 8,
            minute: 0,
            second: 0).date!
        let actual = try DateUtils.parseLocalDate(string: apiReturnDate)

        XCTAssertNoThrow(actual)
        XCTAssertEqual(expect, actual)

        let apiReturnDate1 = "2022/06/10"
        let timeZone1 = TimeZone(identifier: "Asia/Taipei")!

        let expect1 = DateComponents(
            calendar: .current,
            timeZone: timeZone1,
            year: 2022,
            month: 6,
            day: 10,
            hour: 8,
            minute: 0,
            second: 0).date!
        let actual1 = try DateUtils.parseLocalDate(string: apiReturnDate1)

        XCTAssertNoThrow(actual1)
        XCTAssertEqual(expect1, actual1)

        let apiReturnDate2 = "2022-06-10T00:00:00+0800"
        let actual2 = {
            try DateUtils.parseLocalDate(string: apiReturnDate2)
        }

        XCTAssertThrowsError(try actual2())

        let apiReturnDate3 = "2022-06-10T00:00:00.123+0800"
        let actual3 = {
            try DateUtils.parseLocalDate(string: apiReturnDate3)
        }

        XCTAssertThrowsError(try actual3())
    }
}
