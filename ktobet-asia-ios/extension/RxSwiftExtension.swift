import RxSwift
import SharedBu
import RxCocoa
import SwiftyJSON

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
    public func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<Trait, Element> {
        let handler: (Swift.Error) throws -> PrimitiveSequence<Trait, Element> = { (error) in
            let e = transferLogic(error)
            return Single.error(e)
        }
        return catchError(handler)
    }
}

extension ObservableType {
    public func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { error in
            return Driver.empty()
        }
    }
    
    public func asDriverLogError(_ file: StaticString = #file, _ line: UInt = #line) -> SharedSequence<DriverSharingStrategy, Element> {
        return asDriver(onErrorRecover: { print("Error:", $0, " in file:", file, " atLine:", line); return .empty() })
    }
}

extension Completable {
    func asReaktiveCompletable() -> SharedBu.Completable {
        CompletableWrapper(inner: CompletableByEmitterKt.completable(onSubscribe: { emitter in
            let swiftDisposable = self.subscribe {
                emitter.onComplete()
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }
            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        }))
    }
    
    public func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<CompletableTrait, Swift.Never> {
        let handler: (Swift.Error) throws -> PrimitiveSequence<CompletableTrait, Swift.Never> = { (error) in
            let e = transferLogic(error)
            return Completable.error(e)
        }
        return catchError(handler)
    }
}

extension RxSwift.Observable where Element: AnyObject {
    static func from(_ observable: ObservableWrapper<Element>) -> RxSwift.Observable<Element> {
        return RxSwift.Observable<Element>.create { observer in
            let disposable = observable.subscribe(
                isThreadLocal: false,
                onError: { observer.onError($0) },
                onComplete: observer.onCompleted,
                onNext: observer.onNext
            )
            
            return Disposables.create(with: disposable.dispose)
        }
    }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == String {
    func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseList<T>> where T: KotlinBase {
        SingleWrapper(inner: SingleByEmitterKt.single { emitter in
            let swiftDisposable = self.subscribe { jsonString in
                let result = ResponseParser.companion.fromList(jsonStr: jsonString, benSerializable: serial)
                if let data = result.data {
                    let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
                    emitter.onSuccess(value: item)
                } else {
                    let exception = ExceptionFactory.companion.create(message: result.errorMsg ?? "", statusCode: result.statusCode ?? "")
                    emitter.onError(error: exception)
                }
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }

            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }
    
    func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseItem<T>> where T: KotlinBase {
        SingleWrapper(inner: SingleByEmitterKt.single { emitter in
            let swiftDisposable = self.subscribe { jsonString in
                let result = ResponseParser.companion.from(jsonStr: jsonString, benSerializable: serial)
                if let data = result.data {
                    let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
                    emitter.onSuccess(value: item)
                } else {
                    let exception = ExceptionFactory.companion.create(message: result.errorMsg ?? "", statusCode: result.statusCode ?? "")
                    emitter.onError(error: exception)
                }
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }

            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }
    
    func asReaktiveResponseItem<T>() -> SingleWrapper<ResponseItem<T>> where T: Any {
        SingleWrapper(inner: SingleByEmitterKt.single { emitter in
            let swiftDisposable = self.subscribe { jsonString in
                let json = JSON(parseJSON: jsonString)
                if let statusCode = json["statusCode"].string, let errorMsg = json["errorMsg"].string, statusCode.count > 0 && errorMsg.count > 0 {
                    let domain = ""
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["statusCode": statusCode , "errorMsg" : errorMsg]) as Error
                    emitter.onError(error: ExceptionFactory.create(error))
                    return
                }
                let item : ResponseItem<T> = ResponseItem.init(data: json["data"].rawValue as! T, errorMsg: "", node: "", statusCode: "")
                emitter.onSuccess(value: item)
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }
            
            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }

}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == NSArray {
    func asNSArray<T>() -> SingleWrapper<T> where T: Any {
        SingleWrapper(inner: SingleByEmitterKt.single { emitter in
            let swiftDisposable = self.subscribe { array in
                emitter.onSuccess(value: array)
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }
            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }
}

extension RxSwift.Observable where Element == String {
    func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseList<T>> where T: KotlinBase {
        ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
            let swiftDisposable = self.subscribe { jsonString in
                let result = ResponseParser.companion.fromList(jsonStr: jsonString, benSerializable: serial)
                if let data = result.data {
                    let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
                    emitter.onNext(value: item)
                } else {
                    let exception = ExceptionFactory.companion.create(message: result.errorMsg ?? "", statusCode: result.statusCode ?? "")
                    emitter.onError(error: exception)
                }
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }

            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }
    
    func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseItem<T>> where T: KotlinBase {
        ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
            let swiftDisposable = self.subscribe { jsonString in
                let result = ResponseParser.companion.from(jsonStr: jsonString, benSerializable: serial)
                if let data = result.data {
                    let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
                    emitter.onNext(value: item)
                } else {
                    let exception = ExceptionFactory.companion.create(message: result.errorMsg ?? "", statusCode: result.statusCode ?? "")
                    emitter.onError(error: exception)
                }
            } onError: { error in
                emitter.onError(error: ExceptionFactory.create(error))
            }

            emitter.setDisposable(disposable: DisposableWrapper.init(dispoable: swiftDisposable))
        })
    }
}

extension RxSwift.Single where Element: AnyObject {
    static func from(_ single: SingleWrapper<Element>) -> RxSwift.Single<Element> {
        return RxSwift.Single<Element>.create { observer in
            let disposable = single.subscribe(
                isThreadLocal: false,
                onError: { observer(.failure($0)) },
                onSuccess: { observer(.success($0)) }
            )
            
            return Disposables.create(with: disposable.dispose)
        }
    }
}

extension RxSwift.Maybe where Element: AnyObject {
    static func from(_ maybe: MaybeWrapper<Element>) -> RxSwift.Maybe<Element> {
        return RxSwift.Maybe<Element>.create { observer in
            let disposable = maybe.subscribe(
                isThreadLocal: false,
                onError: { observer(.error($0)) },
                onComplete: { observer(.completed) },
                onSuccess: { observer(.success($0)) }
            )
            
            return Disposables.create(with: disposable.dispose)
        }
    }
}

extension RxSwift.Completable {
    static func from(_ completable: CompletableWrapper) -> RxSwift.Completable {
        return RxSwift.Completable.create { observer in
            let disposable = completable.subscribe(
                isThreadLocal: false,
                onError: { observer(.error($0)) },
                onComplete: { observer(.completed) }
            )

            return Disposables.create(with: disposable.dispose)
        }
    }
}

class DisposableWrapper: SharedBu.Disposable {
    private var _dispoable: Disposable
    var isDisposed: Bool = false
    
    init(dispoable: Disposable) {
        _dispoable = dispoable
    }
    
    func dispose() {
        _dispoable.dispose()
        isDisposed = true
    }
}
