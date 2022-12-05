//
//  UserDefaultsExtension.swift
//  ktobet-asia-ios
//
//  Created by Finn Wu on 2022/10/25.
//

import Foundation

extension UserDefaults {
    
    enum Key: Equatable {
        case rememberAccount
        case rememberPassword
        case lastOverLoginLimitDate
        case needCaptcha
        case rememberMe
        case retryCount
        case otpRetryCount
        case countDownEndTime
        case userName
        case cultureCode
        case playerInfoCache
        case lastAPISuccessDate
        case balanceHiddenState(gameId: String)
        case isFirstLaunch
        
        var rawValue: String {
            switch self {
            case .rememberAccount:
                return "rememberAccount"
            case .rememberPassword:
                return "rememberPassword"
            case .lastOverLoginLimitDate:
                return "overLoginLimit"
            case .needCaptcha:
                return "needCaptcha"
            case .rememberMe:
                return "rememberMe"
            case .retryCount:
                return "retryCount"
            case .otpRetryCount:
                return "otpRetryCount"
            case .countDownEndTime:
                return "countDownEndTime"
            case .userName:
                return "userName"
            case .cultureCode:
                return "cultureCode"
            case .playerInfoCache:
                return "playerInfoCache"
            case .lastAPISuccessDate:
                return "lastAPISuccessDate"
            case .balanceHiddenState(let gameId):
                return "balanceHiddenState" + gameId
            case .isFirstLaunch:
                return "isFirstLaunch"
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue == rhs.rawValue
        }
    }
}
