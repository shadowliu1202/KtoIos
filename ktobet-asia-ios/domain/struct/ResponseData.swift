//
//  LoginData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/10.
//

import Foundation
import share_bu


struct ResponseData<T:Codable> : Codable {
    var statusCode : String
    var errorMsg : String
    var node : String?
    var data : T?
}

struct ILoginData : Codable {
    var phase : Int
    var isLocked : Bool
    var status : Int
}

struct SkillData : Codable {
    var skillId : String
}

struct IPlayer : Codable{
    var displayId: String
    var exp: Double
    var gameId: String
    var isAutoUseCoupon: Bool
    var level: Int
    var realName: String
}

struct ILocalizationData : Codable {
    var cultureCode: String
    var data: [String: String]
}

struct OtpStatus : Codable {
    var isMailActive:Bool
    var isSmsActive: Bool
}

struct Nothing : Codable{}
