import Foundation

class DateUtils {
    static func parseOffsetDate(string: String) throws -> Date {
        let parseDate: Date
        let dateFormatter = ISO8601DateFormatter()
        let dateFormatterWithFractionalSeconds = ISO8601DateFormatter()
        dateFormatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = dateFormatter.date(from: string) {
            parseDate = date
        } else if let date = dateFormatterWithFractionalSeconds.date(from: string) {
            parseDate = date
        } else {
            throw KTOError.WrongDateFormat
        }
        
        return parseDate
    }
    
    static func parseLocalDate(string: String) throws -> Date {
        let parseDate = try? DateUtils.parseOffsetDate(string: string)
        
        let parseDateWithFullDate: Date?
        let dateFormatterWithFullDate = ISO8601DateFormatter()
        dateFormatterWithFullDate.formatOptions = [.withFullDate]
        parseDateWithFullDate = dateFormatterWithFullDate.date(from: string)
        
        if parseDateWithFullDate != nil && parseDate == nil {
            return parseDateWithFullDate!
        } else {
            throw KTOError.WrongDateFormat
        }
    }
    
}
