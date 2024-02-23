import Alamofire
import Foundation
import Moya
import sharedbu

enum KTOError: Error {
  case EmptyData
  case WrongDateFormat
  case WrongProductType
  case LostReference
  case JsonParseError
}

struct ResponseParseError: Error {
  let rawData: Data
}

extension KotlinThrowable: Error { }

extension KotlinThrowable {
  var exceptionName: String {
    type(of: self).description()
  }
  
  static func wrapError(_ error: Error) -> KotlinThrowable {
    if let kotlinException = error as? KotlinThrowable {
      return kotlinException
    }
    else {
      return ErrorWrapper(wrapped: error)
    }
  }
  
  func unwrapToError() -> Error {
    if let errorWrapper = self as? ErrorWrapper {
      return errorWrapper.error
    }
    else {
      return self
    }
  }
}

extension ApiException {
  override open func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? ApiException
    else { return false }
    
    return message == object.message && errorCode == object.errorCode
  }
}

class ErrorWrapper: KotlinThrowable {
  let error: Error
  
  init(wrapped error: Error) {
    self.error = error
    super.init()
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? ErrorWrapper
    else { return false }
    
    return (error as NSError) == (object.error as NSError)
  }
}

extension Int {
  func isNetworkConnectionLost() -> Bool {
    [
      NSURLErrorCannotConnectToHost, // -1004
      NSURLErrorCannotFindHost, // -1003
      NSURLErrorDataNotAllowed, // -1020
      NSURLErrorInternationalRoamingOff, // -1018
      NSURLErrorNetworkConnectionLost, // -1005
      NSURLErrorNotConnectedToInternet, // -1009
      NSURLErrorTimedOut // -1001
    ].contains(self)
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
    if let error = (self as? MoyaError), case .statusCode(let response) = error {
      return response.statusCode == 401
    }
    return false
  }

  func isRestrictedArea() -> Bool {
    if let error = (self as? MoyaError), case .statusCode(let response) = error {
      return response.statusCode == 403
    }
    return false
  }

  func isCDNError() -> Bool {
    if let error = (self as? MoyaError), case .statusCode(let response) = error {
      return response.statusCode == 608
    }
    return false
  }

  func isNetworkLost() -> Bool {
    if case let apiException as ApiException = self, let code = Int(apiException.errorCode) {
      return code.isNetworkConnectionLost()
    }
    else if case let moyaError as MoyaError = self {
      return isNetworkLost(moyaError)
    }
    else if case let afError as AFError = self {
      return isNetworkLost(afError)
    }
    else {
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
      }
      else {
        return isNetworkLost(err as NSError)
      }
    default:
      return isNetworkLost(error as NSError)
    }
  }

  private func isNetworkLost(_ error: AFError) -> Bool {
    if
      case .sessionTaskFailed(let err) = error,
      let nsError = err as NSError?
    {
      return isNetworkLost(nsError)
    }
    else {
      return isNetworkLost(error as NSError)
    }
  }

  private func isNetworkLost(_ error: NSError) -> Bool {
    error.code.isNetworkConnectionLost()
  }
}
