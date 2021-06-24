//
//  CommonEnum.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/30.
//

import Foundation

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
}

public enum FeatureType : String {
    case withdraw = "提現"
    case diposit = "充值"
    case callService = "呼叫客服"
    case logout = "登出"
}

public enum Language : String {
    case ZH = "zh-Hans"
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
    case fiatFormat = "^[0-9]{1,}([.][0-9]{0,2})?$"
    case cryptoFormat = "^[0-9]{1,}([.][0-9]{0,8})?$"
}
