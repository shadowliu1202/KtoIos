import RxSwift
import SharedBu

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
    func subscribe(onSuccess: ((Self.Element) -> Void)? = nil,
                   onError: ((Error) -> Void)? = nil ,
                   onException: ((ApiException) -> Void)?) -> RxSwift.Disposable {
        let e: ((Error) -> Void) =  createException(onError: onError, onException: onException)
        return subscribe(onSuccess: onSuccess, onError: e)
    }
}

extension ObservableType {
    func subscribe(onNext: ((Self.Element) -> Void)? = nil,
                   onError: ((Error) -> Void)? = nil,
                   onException: ((ApiException) -> Void)? = nil,
                   onCompleted: (() -> Void)? = nil,
                   onDisposed: (() -> Void)? = nil) -> RxSwift.Disposable {
        let e: ((Error) -> Void) =  createException(onError: onError, onException: onException)
        return subscribe(onNext: onNext,
                         onError: e,
                         onCompleted: onCompleted,
                         onDisposed: onDisposed)
    }
}

///Completable
extension PrimitiveSequenceType where Trait == CompletableTrait, Element == Swift.Never {
    func subscribe(onCompleted: (() -> Void)? = nil,
                   onException: ((ApiException) -> Void)? = nil,
                   onError: ((Swift.Error) -> Void)? = nil) -> Disposable {
        let e: ((Error) -> Void) =  createException(onError: onError, onException: onException)
        return subscribe(onCompleted: onCompleted, onError: e)
    }
}

func createException(onError: ((Error) -> Void)? = nil , onException: ((ApiException) -> Void)?) -> ((Error) -> Void){
    return { error in
        let err = error as NSError
        let exception = ExceptionFactory
            .Companion.init()
            .create(message: err.userInfo["errorMsg"] as? String ?? "",
                    statusCode: err.userInfo["statusCode"] as? String ?? "")
        if exception is ApiUnknownException {
            onError?(error)
        } else {
            onException?(exception)
        }
    }
}
