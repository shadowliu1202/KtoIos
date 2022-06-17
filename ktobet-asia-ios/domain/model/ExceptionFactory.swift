import SharedBu
import Moya
import Alamofire

extension ExceptionFactory {
    static func create(_ error: Error) -> ApiException {
        switch error {
        case let moyaError as MoyaError:
            return ExceptionFactory.create(moyaError)
        case let afError as AFError:
            return ExceptionFactory.create(afError)
        case let nsError as NSError:
            return ExceptionFactory.create(nsError)
        default:
            return ExceptionFactory.create(error as NSError)
        }
    }
    
    private static func create(_ error: MoyaError) -> ApiException {
        if case .statusCode(let response) = error {
            let code = "\(response.statusCode)"
            let exception = ExceptionFactory
                .Companion.init()
                .create(message: error.errorDescription ?? "", statusCode: code)
            return exception
        } else if case .underlying(let afError, _) = error {
            return ExceptionFactory.create(afError as! AFError)
        } else {
            return ApiUnknownException(message: "\(error.response?.description ?? "")", errorCode: "\(error.response?.statusCode ?? 0)")
        }
    }
    private static func create(_ error: AFError) -> ApiException {
        if case .sessionTaskFailed(let err) = error,
            let nsError = err as NSError? {
            return ExceptionFactory.create(nsError)
        } else {
            return ApiUnknownException(message: error.errorDescription ?? "", errorCode: "\(error.responseCode ?? 0)")
        }
    }
    private static func create(_ error: NSError) -> ApiException {
        let exception = ExceptionFactory
            .Companion.init()
            .create(message: error.userInfo["errorMsg"] as? String ?? "", statusCode: error.userInfo["statusCode"] as? String ?? "")
        return exception

    }
}
