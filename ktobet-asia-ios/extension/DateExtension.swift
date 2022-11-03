import Foundation
import SharedBu


extension Date {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        let timezone = Foundation.TimeZone(secondsFromGMT: 0)!
        calendar.timeZone = timezone
        return calendar
    }
    
    func adding(value: Int, byAdding: Calendar.Component) -> Date {
        return Calendar.current.date(byAdding: byAdding, value: value, to: self)!
    }
    
    private func convertToDateComponent(dateType: Calendar.Component) -> Int? {
        let components = calendar.dateComponents([dateType], from: self)
        switch dateType {
        case .year:
            return components.year
        case .month:
            return components.month
        case .day:
            return components.day
        case .hour:
            return components.hour
        case .minute:
            return components.minute
        case .second:
            return components.second
        case .nanosecond:
            return (components.nanosecond! + 500) / 1000000 * 1000000
        default:
            return nil
        }
    }
    
    func getYear() -> Int32 {
        return Int32(convertToDateComponent(dateType: .year) ?? 0)
    }
    
    func getMonth() -> Int32 {
        return Int32(convertToDateComponent(dateType: .month) ?? 1)
    }
    
    func getDayOfMonth() -> Int32 {
        return Int32(convertToDateComponent(dateType: .day) ?? 1)
    }
    
    func getHour() -> Int32 {
        return Int32(convertToDateComponent(dateType: .hour) ?? 0)
    }
    
    func getMinute() -> Int32 {
        return Int32(convertToDateComponent(dateType: .minute) ?? 0)
    }
    
    func getSecond() -> Int32 {
        return Int32(convertToDateComponent(dateType: .second) ?? 0)
    }
    
    func getNanosecond() -> Int32 {
        return Int32(convertToDateComponent(dateType: .nanosecond) ?? 0)
    }
    
    func formated(withFormat format: String = "yyyy/MM/dd") -> Date? {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = format
        let dateString = formatter.string(from: self)
        return formatter.date(from: dateString)
    }
    
    func daysSince(_ anotherDate: Date) -> Int? {
        if let fromDate = dateFromComponents(self), let toDate = dateFromComponents(anotherDate) {
            let components = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
            return components.day
        }
        return nil
    }
    
    private func dateFromComponents(_ date: Date) -> Date? {
        let calender   = Calendar.current
        let components = calender.dateComponents([.year, .month, .day], from: date)
        return calender.date(from: components)
    }
    
    func toDateStartTimeString(with SeparatorSymbol: String = "/") -> String {
        let comp = calendar.dateComponents([.year, .month, .day], from: self)
        let year = comp.year
        let month = comp.month
        let dayOfMonth = comp.day
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d %02d:%02d:%02d", year!, month!, dayOfMonth!, 00, 00, 00)
    }
    
    func toDateString(with SeparatorSymbol: String = "/") -> String {
        let comp = calendar.dateComponents([.year, .month, .day], from: self)
        let year = comp.year
        let month = comp.month
        let dayOfMonth = comp.day
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", year!, month!, dayOfMonth!)
    }
    
    func toTimeString(with SeparatorSymbol: String = "/") -> String {
        let comp = calendar.dateComponents([.hour, .minute, .second], from: self)
        let hour = comp.hour
        let minute = comp.minute
        let second = comp.second
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", hour!, minute!, second!)
    }
    
    func toMonthDayString(with SeparatorSymbol: String = "/") -> String {
        let comp = Calendar.current.dateComponents([.month, .day], from: self)
        let month = comp.month
        let dayOfMonth = comp.day
        return String(format: "%02d\(SeparatorSymbol)%02d", month!, dayOfMonth!)
    }
    
    func toYearMonthString(with SeparatorSymbol: String = "/") -> String {
        let comp = Calendar.current.dateComponents([.year, .month], from: self)
        let year = comp.year
        let month = comp.month
        return String(format: "%02d\(SeparatorSymbol)%02d", year!, month!)
    }
    
    func convertdateToUTC() -> Date {
        var comp = Calendar.current.dateComponents([.year, .month, .day], from: self)
        comp.timeZone = Foundation.TimeZone(abbreviation: "UTC")!
        return Calendar.current.date(from: comp)!
    }
    
    func betweenTwoDay(sencondDate: Date) -> Int {
        let calendar = Calendar.current
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: sencondDate)
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }
    
    func betweenTwoMonth(from date: Date) -> Int32 {
        let m1 = self.getMonth() - date.getMonth()
        let m2 = (self.getYear() - date.getYear()) * 12
        return m1 + m2
    }
    
    var startOfMonth: Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)
        return  calendar.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
    func getPastSevenDate() -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = -6
        let pastSevenDate = Calendar.current.date(byAdding: dateComponent, to: self)!
        return pastSevenDate
    }
    
    static func getMinimumAdultBirthday() -> Date {
        Date().adding(value: -adultAge, byAdding: .year)
    }
    
    func convertToKotlinx_datetimeLocalDateTime() -> SharedBu.LocalDateTime {
        return SharedBu.LocalDateTime.init(year: self.getYear(), monthNumber: self.getMonth(), dayOfMonth: self.getDayOfMonth(), hour: self.getHour(), minute: self.getMinute(), second: self.getSecond(), nanosecond: self.getNanosecond())
    }
    
    func convertToKotlinx_datetimeLocalDate() -> SharedBu.LocalDate {
        return SharedBu.LocalDate.init(year: self.getYear(), monthNumber: self.getMonth(), dayOfMonth: self.getDayOfMonth())
    }
    
    func toUTCOffsetDateTime() -> OffsetDateTime {
        let createLocalDateTime = SharedBu.LocalDateTime(year: self.getYear(), monthNumber: self.getMonth(), dayOfMonth: self.getDayOfMonth(), hour: self.getHour(), minute: self.getMinute(), second: self.getSecond(), nanosecond: self.getNanosecond())
        let offsetDateTime = OffsetDateTime.Companion.init().create(localDateTime: createLocalDateTime, zoneId: "UTC+0")
        return offsetDateTime
    }
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    
    func calculateAge(birthday: String) -> Int? {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy/MM/dd"
        if let birthdayDate = dateFormater.date(from: birthday) {
            let components = calendar.dateComponents([.year], from: birthdayDate, to: self)
            return components.year
        }
        return nil
    }
    
    func calculateAge(birthday: Date) -> Int? {
        let components = calendar.dateComponents([.year], from: birthday, to: self)
        return components.year
    }
}


extension OffsetDateTime {
    func convertToDate() -> Date {
        return Date(timeIntervalSince1970: Double(self.toInstant().epochSeconds))
    }
    
    func toDateTimeString(with SeparatorSymbol: String = "/") -> String {
        let year = self.year
        let month = self.monthNumber
        let dayOfMonth = self.dayOfMonth
        let hour = self.hour
        let minute = self.minute
        let second = self.second
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d %02d:%02d:%02d", year, month, dayOfMonth, hour, minute, second)
    }
    
    func toTimeString(with SeparatorSymbol: String = ":") -> String {
        let hour = self.hour
        let minute = self.minute
        let second = self.second
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", hour, minute, second)
    }
    
    func toDateString() -> String {
        let year = self.year
        let month = self.monthNumber
        let dayOfMonth = self.dayOfMonth
        return String(format: "%02d/%02d/%02d", year, month, dayOfMonth)
    }
}

extension SharedBu.LocalDateTime {
    func convertToDate(with SeparatorSymbol: String = "-") -> Date {
        let date = String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d %02d:%02d:%02d.%03d", self.year, self.monthNumber, self.dayOfMonth, self.hour, self.minute, self.second, self.nanosecond)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = Foundation.TimeZone.current
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: date) ?? Date()
    }
    
    func toDateTimeFormatString(with SeparatorSymbol: String = "/") -> String {
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d %02d:%02d:%02d", self.year, self.monthNumber, self.dayOfMonth, self.hour, self.minute, self.second)
    }
    
    func toDateFormatString(with SeparatorSymbol: String = "/") -> String {
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", self.year, self.monthNumber, self.dayOfMonth)
    }
    
    func toTimeString(with SeparatorSymbol: String = ":") -> String {
        let hour = self.hour
        let minute = self.minute
        let second = self.second
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", hour, minute, second)
    }

    func toQueryFormatString(timeZone: SharedBu.TimeZone) -> String {
        let instant = SharedBu.TimeZone.companion.UTC.toInstant(self)
        let utcOffset = instant.offsetIn(timeZone: timeZone)
        return "\(self)\(utcOffset)"
    }
}

extension SharedBu.LocalDate {
    func convertToDate(with SeparatorSymbol: String = "-") -> Date {
        let date = String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", self.year, self.monthNumber, self.dayOfMonth)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        dateFormatter.timeZone = Foundation.TimeZone(abbreviation: "UTC")!
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: date) ?? Date()
    }
    
    func toDateFormatString(with SeparatorSymbol: String = "/") -> String {
        return String(format: "%02d\(SeparatorSymbol)%02d\(SeparatorSymbol)%02d", self.year, self.monthNumber, self.dayOfMonth)
    }
    
    func toBetDisplayDate() -> String {
        let today = Date().convertdateToUTC().toDateString(with: "-")
        let yesterday = Date().adding(value: -1, byAdding: .day).convertdateToUTC().toDateString(with: "-")
        let betDateString = self.toDateFormatString(with: "-")
        if betDateString == today {
            return Localize.string("common_today")
        } else if betDateString == yesterday {
            return Localize.string("common_yesterday")
        } else {
            return betDateString.replacingOccurrences(of: "-", with: "/")
        }
    }
    
}

extension SharedBu.Instant {
    private func convertToDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self.epochSeconds))
    }
    
    private func convertToDateString(_ dateFormat: String) -> String {
        let localRepo = Injectable.resolve(LocalStorageRepository.self)!
        let date = self.convertToDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = localRepo.localeTimeZone()
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    func toDateTimeString(with SeparatorSymbol: String = "/") -> String {
        let dateFormat = "yyyy\(SeparatorSymbol)MM\(SeparatorSymbol)dd HH:mm:ss"
        return convertToDateString(dateFormat)
    }
    
    func toDateString(with SeparatorSymbol: String = "/") -> String {
        let dateFormat = "yyyy\(SeparatorSymbol)MM\(SeparatorSymbol)dd"
        return convertToDateString(dateFormat)
    }
    
    func toTimeString() -> String {
        let dateFormat = "HH:mm:ss"
        return convertToDateString(dateFormat)
    }
    
}

extension SharedBu.TimeZone {

    func toFoundation() -> Foundation.TimeZone {
        return Foundation.TimeZone(identifier: self.id)!
    }
    
    static func fromFoundation(_ timeZone: Foundation.TimeZone) -> SharedBu.TimeZone {
        return SharedBu.TimeZone.companion.of(zoneId: timeZone.identifier)
    }
}

