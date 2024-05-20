import Alamofire
import Foundation
import Moya
import RxSwift
import sharedbu

extension APPError {
    enum DefaultStatusCode: Int {
        case sharedBuError = -1
        case moyaError = -2
        case responseParseError = -3
        case navigationManagement = -4
        case requestTimeout = -5
    }
}

enum APPError: Equatable {
    case unknown(NSError)
    case networkLost
    case regionRestricted
    case tooManyRequest
    case temporary
    case cdn
    case maintenance
    case wrongFormat
    case ignorable
  
    static func convert(by error: Error) -> Self {
        switch error {
        case let error as KotlinThrowable:
            return handlesharedbuError(error)
        case let error as MoyaError:
            return handleMoyaError(error)
        case let error as ResponseParseError:
            return handleResponseParseError(error)
        default:
            return handleUnexpectedError(error)
        }
    }
  
    private static func handlesharedbuError(_ error: KotlinThrowable) -> Self {
        let nsError: NSError
        switch error {
        case let error as ApiException:
            nsError = NSError(
                domain: "ApiException",
                code: Int(error.errorCode) ?? DefaultStatusCode.sharedBuError.rawValue,
                userInfo: [
                    "StatusCode": error.errorCode,
                    "ErrorMessage": error.message ?? "",
                    "ExceptionName": error.exceptionName,
                    "StackTrace": convertKotlinStringArrayToString(error.getStackTrace())
                ])
    
        case let error as KtoException:
            nsError = NSError(
                domain: "KtoException",
                code: Int(error.errorCode ?? "") ?? DefaultStatusCode.sharedBuError.rawValue,
                userInfo: [
                    "StatusCode": error.errorCode ?? "",
                    "ErrorMessage": error.message ?? "",
                    "ExceptionName": error.exceptionName,
                    "StackTrace": convertKotlinStringArrayToString(error.getStackTrace())
                ])
    
        default:
            nsError = NSError(
                domain: "KotlinException",
                code: DefaultStatusCode.sharedBuError.rawValue,
                userInfo: [
                    "ErrorMessage": error.message ?? "",
                    "ExceptionName": error.description(),
                    "StackTrace": convertKotlinStringArrayToString(error.getStackTrace())
                ])
        }
    
        return .unknown(nsError)
    }
  
    private static func convertKotlinStringArrayToString(_ kotlinArray: KotlinArray<NSString>) -> String {
        var swiftArray: [String] = []
        for i in 0..<kotlinArray.size {
            if let str = kotlinArray.get(index: i) as String? {
                swiftArray.append(str)
            }
        }
    
        return swiftArray.joined(separator: "\n")
    }
  
    private static func handleMoyaError(_ error: MoyaError) -> Self {
        guard !isExplicitlyCancelledError(error) else { return .ignorable }
        guard !isMappingError(error) else { return .wrongFormat }
      
        var domain = "MoyaError"
        var code = error.response?.statusCode ?? DefaultStatusCode.moyaError.rawValue
        var userInfo: [String: Any?] = ["ErrorDescription": error.errorDescription]
      
        if
            let underlyingError = error.errorUserInfo[NSUnderlyingErrorKey] as? AFError,
            let afUnderlyingError = underlyingError.underlyingError as? NSError
        {
            guard !afUnderlyingError.code.isNetworkConnectionLost() else { return .networkLost }
      
            userInfo.merge(afUnderlyingError.userInfo) { _, new in new }
            userInfo["Source"] = "Moya"
            domain = afUnderlyingError.domain
            code = afUnderlyingError.code
        }
      
        if let moyaResponse = error.response {
            userInfo["RequestURL"] = moyaResponse.request?.url?.absoluteString
            userInfo["ResponseHeader"] = moyaResponse.request?.allHTTPHeaderFields
            userInfo["ResponseBody"] = String(data: moyaResponse.data, encoding: .utf8)
        }
      
        let nsError = NSError(
            domain: domain,
            code: code,
            userInfo: userInfo.compactMapValues { $0 })
      
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
        case 403: return .regionRestricted
        case 404: return .unknown(nsError)
        case 410: return .maintenance
        case 429: return .tooManyRequest
        case 502: return process502(nsError, errorResponse)
        case 503: return .temporary
        case 608: return .cdn
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
        let nsError = NSError(
            domain: "ResponseParseError",
            code: DefaultStatusCode.responseParseError.rawValue,
            userInfo: ["RawData": error.rawData])
    
        return .unknown(nsError)
    }
  
    private static func handleUnexpectedError(_ error: Error) -> Self {
        .unknown(error as NSError)
    }
}
