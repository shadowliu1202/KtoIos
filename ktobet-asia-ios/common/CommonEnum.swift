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

enum UserInfoStatus{
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
