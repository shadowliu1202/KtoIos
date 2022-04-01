//
//  CommonEnum.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/30.
//

import Foundation
import SharedBu
import Lottie

public enum AccountType: Int {
    case phone = 2
    case email = 1
}

public enum UserInfoStatus{
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
    func toValidError() -> ValidError {
        switch self {
        case .exceededlength:
            return .length
        case .mustfill:
            return .empty
        case .malformed:
            return .regex
        case .none:
            return .none
        default:
            return .none
        }
    }
}

extension BankBranchPatternValidateResult {
    func toValidError() -> ValidError {
        switch self {
        case .exceededlength:
            return .length
        case .mustfill:
            return .empty
        case .malformed:
            return .regex
        case .none:
            return .none
        default:
            return .none
        }
    }
}

public enum FeatureType {
    case withdraw
    case deposit
    case callService
    case logout
}

public enum Language : String {
    case ZH = "zh-cn"
    case VI = "vi"
    case TH = "th"
}

public enum DateType {
    case week(fromDate: Date = Date(), toDate: Date = Date())
    case day(Date)
    case month(fromDate: Date, toDate: Date)
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
    case Message, Dispatched, Queued, Join, Close, DuplicateConnect
}

enum BithdayValidError {
    case none
    case empty
    case notAdult
}
