import SharedBu
import Moya

extension ExceptionFactory {
    static func create(_ error: Error) -> ApiException {
        switch error {
        case let moyaError as MoyaError:
            return ExceptionFactory.companion.create(message: moyaError.response?.description ?? "", statusCode: "\(moyaError.response?.statusCode ?? 0)")
        case let nsError as NSError:
            return ExceptionFactory.companion.create(message: nsError.userInfo["errorMsg"] as? String ?? "",
                                                     statusCode: nsError.userInfo["statusCode"] as? String ?? "")
        default:
            return ApiException(message: nil, errorCode: nil)
        }
    }
}
