import SharedBu

extension ExceptionFactory {
    static func create(_ error: Error) -> ApiException {
        if let ktoError = error as? KotlinError, let exception = ktoError.throwable as? ApiException {
            return exception
        } else {
            let err = error as NSError
            let exception = ExceptionFactory
                .Companion.init()
                .create(message: err.userInfo["errorMsg"] as? String ?? "",
                        statusCode: err.userInfo["statusCode"] as? String ?? "")
            return exception
        }
    }
}
