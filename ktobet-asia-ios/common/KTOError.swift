//
//  ErrorType.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/14.
//

import Foundation
import SharedBu

class LoginError : NSError{
    var status : LoginStatus.TryStatus?
    var isLock : Bool?
}

enum KTOError: Error {
    case EmptyData
}
extension ApiException: Error {}
extension KtoException: Error {}
class NoSuchElementException: KtoException {}
