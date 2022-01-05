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
    
    static func toKtoException(_ error: Error) -> Error {
        let exception = ExceptionFactory.create(error)
        switch exception {
        case is PlayerCryptoBankCardIsExist:
            return KtoWithdrawalAccountExist()
        case is ChatCheckGuestFail:
            return ChatCheckGuestIPFail()
        case is PlayerWithdrawalRequestCryptoRateChange:
            return KtoRequestCryptoRateChange()
        case is PlayerWithdrawalDefective:
            return KtoPlayerWithdrawalDefective()
        default:
            return error
        }
    }
}
