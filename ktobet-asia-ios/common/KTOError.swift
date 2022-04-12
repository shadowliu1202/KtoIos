//
//  ErrorType.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/14.
//

import Foundation
import SharedBu
import Moya

class LoginError : NSError{
    var status : LoginStatus.TryStatus?
    var isLock : Bool?
}

enum KTOError: Error {
    case EmptyData
}

extension KotlinThrowable: Error {}
class NoSuchElementException: KtoException {}

extension Int {
    func isNetworkConnectionLost() -> Bool {
        switch self {
        case NSURLErrorNetworkConnectionLost,//-1005
             NSURLErrorNotConnectedToInternet,//-1009
             NSURLErrorCannotConnectToHost,//-1004
             NSURLErrorCannotFindHost,//-1003
             NSURLErrorTimedOut,//-1001
             NSURLErrorInternationalRoamingOff,//-1018
             NSURLErrorDataNotAllowed://-1020
            return true
        default:
            return false
        }
    }
}

extension Error {
    func isMaintenance() -> Bool {
        if let error = (self as? MoyaError) {
            switch error {
            case .statusCode(let response):
                return response.statusCode == 410
            default:
                return false
            }
        }

        return false
    }
    
    func isUnauthorized() -> Bool {
        if let error = (self as? MoyaError), case let .statusCode(response) = error {
            return response.statusCode == 401
        }
        return false
    }
}
