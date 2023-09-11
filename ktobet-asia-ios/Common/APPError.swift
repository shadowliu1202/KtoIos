import Alamofire
import Foundation
import Moya
import RxSwift
import SharedBu

enum APPError: Equatable {
  case unknown(NSError)
  case regionRestricted(NSError)
  case tooManyRequest(NSError)
  case temporary(NSError)
  case cdn(NSError)
  case maintenance(NSError)
  case wrongFormat
  case ignorable
  
  static func convert(by error: Error) -> Self {
    switch error {
    case let error as KotlinThrowable:
      return handleSharedBuError(error)
    case let error as MoyaError:
      return handleMoyaError(error)
    case let error as ResponseParseError:
      return handleResponseParseError(error)
    default:
      return handleUnexpectedError(error)
    }
  }
  
  private static func handleSharedBuError(_ error: KotlinThrowable) -> Self {
    let nsError: NSError
    switch error {
    case let error as ApiException:
      nsError = NSError(
        domain: "ApiException",
        code: Int(error.errorCode) ?? -1,
        userInfo: ["StatusCode": error.errorCode, "ErrorMessage": error.message ?? "", "ExceptionName": error.exceptionName])
    
    case let error as KtoException:
      nsError = NSError(
        domain: "KtoException",
        code: Int(error.errorCode ?? "") ?? -1,
        userInfo: [
          "StatusCode": error.errorCode ?? "",
          "ErrorMessage": error.message ?? "",
          "ExceptionName": error.exceptionName
        ])
    
    default:
      nsError = NSError(
        domain: "KotlinException",
        code: -1,
        userInfo: ["ErrorMessage": error.message ?? "", "ExceptionName": error.exceptionName])
    }
    
    return .unknown(nsError)
  }
  
  private static func handleMoyaError(_ error: MoyaError) -> Self {
    guard !isExplicitlyCancelledError(error) else { return .ignorable }
    guard !isMappingError(error) else { return .wrongFormat }
    
    let errorDescription = error.errorDescription ?? ""
    var statusCode = ""
    var requestURL = ""
    var responseHeader = ["": ""]
    var responseBody = ""
    
    if let moyaResponse = error.response {
      statusCode = "\(moyaResponse.statusCode)"
      requestURL = moyaResponse.request?.url?.absoluteString ?? ""
      responseHeader = moyaResponse.request?.allHTTPHeaderFields ?? ["": ""]
      responseBody = String(data: moyaResponse.data, encoding: .utf8) ?? ""
    }
    
    let nsError = NSError(
      domain: "MoyaError",
      code: Int(statusCode) ?? -2,
      userInfo: [
        "RequestURL": requestURL,
        "ErrorDescription": errorDescription,
        "ResponseHeader": responseHeader,
        "ResponseBody": responseBody
      ])
    
    return processHTTPCode(nsError)
  }
  
  private static func isExplicitlyCancelledError(_ error: MoyaError) -> Bool {
    if
      case .underlying(let underlyingError, _) = error,
      let afError = underlyingError.asAFError,
      afError.isExplicitlyCancelledError
    {
      return true
    }
    else { return false }
  }
  
  private static func isMappingError(_ error: MoyaError) -> Bool {
    switch error {
    case .encodableMapping,
         .imageMapping,
         .jsonMapping,
         .objectMapping,
         .stringMapping: return true
      
    case .parameterEncoding,
         .requestMapping,
         .statusCode,
         .underlying: return false
    }
  }
  
  private static func processHTTPCode(_ nsError: NSError, errorResponse: Response? = nil) -> Self {
    let statusCode = nsError.code
    
    switch statusCode {
    case 401: return process401(nsError)
    case 403: return .regionRestricted(nsError)
    case 404: return .unknown(nsError)
    case 410: return .maintenance(nsError)
    case 429: return .tooManyRequest(nsError)
    case 502: return process502(nsError, errorResponse)
    case 503: return .temporary(nsError)
    case 608: return .cdn(nsError)
    default: return .unknown(nsError)
    }
  }
  
  private static func process401(_ nsError: NSError) -> Self {
    @Injected(name: "CheckingIsLogged") var tracker: ActivityIndicator
    guard !tracker.isLoading else { return .ignorable }
    
    return .unknown(nsError)
  }
  
  private static func process502(_ nsError: NSError, _ errorResponse: Response?) -> Self {
    if
      let errorResponse,
      let info = parse502Html(errorResponse)
    {
      let newNSError = NSError(
        domain: nsError.domain,
        code: nsError.code,
        userInfo: nsError.userInfo.merging(info) { current, _ in current })
      
      return .unknown(newNSError)
    }
    else {
      return .unknown(nsError)
    }
  }
  
  private static func parse502Html(_ response: Response) -> [String: String]? {
    guard let rawHtml = String(data: response.data, encoding: .utf8) else { return nil }
    
    return [
      "502_Detail": self.groups("<div class=message>(.*?)</div>", from: rawHtml).first?.last ?? "",
      "502_Message": self.groups("<div class=detail>(.*?)</div>", from: rawHtml).first?.last?.removeHtmlTag() ?? "",
      "502_HOST": response.request?.url?.host ?? ""
    ]
  }
  
  private static func groups(_ regexPattern: String, from: String) -> [[String]] {
    let regex = try? NSRegularExpression(pattern: regexPattern)
    
    return regex?.matches(
      in: from,
      range: NSRange(from.startIndex..., in: from))
      .map { match in
        (0..<match.numberOfRanges).map {
          let rangeBounds = match.range(at: $0)
          guard let range = Range(rangeBounds, in: from) else { return "" }
          return String(from[range])
        }
      } ?? []
  }
  
  private static func handleResponseParseError(_ error: ResponseParseError) -> Self {
    let nsError = NSError(domain: "ResponseParseError", code: -3, userInfo: ["RawData": error.rawData])
    
    return .unknown(nsError)
  }
  
  private static func handleUnexpectedError(_ error: Error) -> Self {
    .unknown(error as NSError)
  }
}
