import SharedBu

extension ExceptionFactory {
    static func create(_ error: Error) -> ApiException {
        let err = error as NSError
        let exception = ExceptionFactory
            .Companion.init()
            .create(message: err.userInfo["errorMsg"] as? String ?? "",
                    statusCode: err.userInfo["statusCode"] as? String ?? "")
        return exception
    }
}
