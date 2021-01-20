//
//  RequestData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/16.
//

import Foundation
import share_bu


struct LoginRequest : Encodable{
    var account : String
    var password : String
    var captcha : String
}

struct IRegisterRequest : Encodable {
    var account: String?
    var accountType: Int?
    var currencyCode: String?
    var password: String?
    var realName: String?
}

struct IVerifyOtpRequest : Encodable {
    var verifyCode: String?
}

struct IResetPasswordRequest : Encodable {
    var account: String?
    var accountType: Int?
}

struct INewPasswordRequest : Encodable {
    var newPassword : String?
}

struct Empty : Encodable {}
