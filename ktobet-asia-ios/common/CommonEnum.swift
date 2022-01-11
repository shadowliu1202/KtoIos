//
//  CommonEnum.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/30.
//

import Foundation
import SharedBu

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

public enum FeatureType : String {
    case withdraw = "提現"
    case diposit = "充值"
    case callService = "呼叫客服"
    case logout = "登出"
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
}


struct Setting {
    static let resendOtpCountDownSecond: Double = 240
}

enum ChatTarget: String {
    case Message, Dispatched, Queued, Join, Close, DuplicateConnect
}
