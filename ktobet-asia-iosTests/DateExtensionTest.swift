import XCTest
import SharedBu

@testable import ktobet_asia_ios_qat
class DateExtensionTest: XCTestCase {
    
    func testOffsetDateTimeToDate() throws {
        let timeZoneID = "Asia/Taipei"
        
        let expect = DateComponents.init(calendar: .current, timeZone: Foundation.TimeZone(identifier: timeZoneID), year: 2022, month: 6, day: 7, hour: 12, minute: 0, second: 0).date
        
        let actualLocalDateTime = SharedBu.LocalDateTime.init(year: 2022, month: SharedBu.Month.june, dayOfMonth: 7, hour: 12, minute: 0, second: 0, nanosecond: 0)
        let actualTimeZone = SharedBu.TimeZone.companion.of(zoneId: timeZoneID)
        let offsetDateTime = SharedBu.OffsetDateTime.init(localDateTime: actualLocalDateTime, timeZone: actualTimeZone)
        
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
}
