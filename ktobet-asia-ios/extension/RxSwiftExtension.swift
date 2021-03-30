import RxSwift
import share_bu

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
    func subscribe(onSuccess: ((Self.Element) -> Void)? = nil,
                   onError: ((Error) -> Void)? = nil ,
                   onException: ((ApiException) -> Void)?) -> RxSwift.Disposable {
        
        let e: ((Error) -> Void) =  { error in
            let exception = ExceptionFactory
                .Companion.init()
                .create(message: (error as NSError).localizedDescription,
                        statusCode: String((error as NSError).code))
            if exception is ApiUnknownException {
                onError?(error)
            } else {
                onException?(exception)
            }
        }
        return subscribe(onSuccess: onSuccess, onError: e)
    }
}

extension ObservableType {
    func subscribe(onNext: ((Self.Element) -> Void)? = nil,
                   onError: ((Error) -> Void)? = nil,
                   onException: ((ApiException) -> Void)? = nil,
                   onCompleted: (() -> Void)? = nil,
                   onDisposed: (() -> Void)? = nil) -> RxSwift.Disposable {
        
        let e: ((Error) -> Void) =  { error in
            let exception = ExceptionFactory
                .Companion.init()
                .create(message: (error as NSError).localizedDescription,
                        statusCode: String((error as NSError).code))
            if exception is ApiUnknownException {
                onError?(error)
            } else {
                onException?(exception)
            }
        }
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
        let e: ((Error) -> Void) =  { error in
            let exception = ExceptionFactory
                .Companion.init()
                .create(message: (error as NSError).localizedDescription,
                        statusCode: String((error as NSError).code))
            if exception is ApiUnknownException {
                onError?(error)
            } else {
                onException?(exception)
            }
        }
        return subscribe(onCompleted: onCompleted, onError: e)
    }
}
