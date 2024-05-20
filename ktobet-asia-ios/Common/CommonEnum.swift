import Foundation
import Lottie
import sharedbu

public enum AccountType: Int {
    case phone = 2
    case email = 1
}

public enum UserInfoStatus {
    case valid
    case firstEmpty
    case empty
    case errNameFormat
    case errEmailFormat
    case errPhoneFormat
    case errPasswordFormat
    case errPasswordNotMatch
    case errEmailOtpInactive
    case errSMSOtpInactive
    case errOtpServiceDown
}

public enum ValidError {
    case none
    case length
    case empty
    case regex
}

extension BankNamePatternValidateResult {
    var localizeDescription: String {
        switch self {
        case .exceededLength,
             .malformed:
            return Localize.string("common_invalid")
        case .mustFill:
            return Localize.string("common_field_must_fill")
        case .none:
            return ""
        }
    }
}

extension BankBranchPatternValidateResult {
    var localizeDescription: String {
        switch self {
        case .exceededLength,
             .malformed:
            return Localize.string("common_invalid")
        case .mustFill:
            return Localize.string("common_field_must_fill")
        case .none:
            return ""
        }
    }
}

public enum FeatureType {
    case withdraw
    case deposit
    case callService
    case logout
}

public enum DateType {
    case week(fromDate: Date = Date(), toDate: Date = Date())
    case day(Date)
    case month(fromDate: Date, toDate: Date)
}

extension DateType {
    var result: (from: Date, to: Date) {
        switch self {
        case .week(let from, let to):
            return (from, to)
        case .day(let date):
            return (date, date)
        case .month(let from, let to):
            return (from, to)
        }
    }
}

public enum RegularFormat: String {
    case currencyFormatWithTwoDecimal = "^[0-9]{1,8}([.][0-9]{0,2})?$"
    case currencyFormat = "^[0-9]{1,8}?$"
}

struct Setting {
    static let resendOtpCountDownSecond: Double = 240
    static let resetPasswordStep2CountDownSecond: Double = 600
    static let otpRetryLimit = 6
}

struct CoomonUISetting {
    static let bottomSpace: CGFloat = 96
}

enum ChatTarget: String {
    case Message
    case Dispatched
    case Queued
    case Join
    case Close
    case DuplicateConnect
}

enum BithdayValidError {
    case none
    case empty
    case notAdult
}
