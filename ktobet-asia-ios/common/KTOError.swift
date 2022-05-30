//
//  ErrorType.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/14.
//

import Foundation
import SharedBu
import Alamofire
import Moya

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
    
    func isNetworkLost() -> Bool {
        if case let apiException as ApiException = self, let errorCode = apiException.errorCode, let code = Int(errorCode) {
            return code.isNetworkConnectionLost()
        } else if case let moyaError as MoyaError = self {
            return isNetworkLost(moyaError)
        } else if case let afError as AFError = self {
            return isNetworkLost(afError)
        } else {
            return isNetworkLost(self as NSError)
        }
    }
    private func isNetworkLost(_ error: MoyaError) -> Bool {
        switch error {
        case .statusCode(let response):
            return response.statusCode.isNetworkConnectionLost()
        case .underlying(let err, _):
            if err is AFError {
                return isNetworkLost(err as! AFError)
            } else {
                return isNetworkLost(err as NSError)
            }
        default:
            return isNetworkLost(error as NSError)
        }
    }
    private func isNetworkLost(_ error: AFError) -> Bool {
        if case .sessionTaskFailed(let err) = error,
            let nsError = err as NSError? {
            return isNetworkLost(nsError)
        } else {
            return isNetworkLost(error as NSError)
        }
    }
    private func isNetworkLost(_ error: NSError) -> Bool {
        return error.code.isNetworkConnectionLost()
    }
}
