import Foundation
import RxCocoa
import RxSwift
import sharedbu
import SwiftyJSON

// MARK: - ObservableType

extension ObservableType {
  public func asDriverOnErrorJustComplete() -> Driver<Element> {
    asDriver { _ in
      Driver.empty()
    }
  }
}

extension ObservableType where Element: Sequence {
  func forceCast<Element>(_: Element.Type) -> Observable<[Element]> {
    self.map {
      $0.compactMap { $0 as? Element }
    }
  }
}

// MARK: - Observable

extension RxSwift.Observable where Element: AnyObject {
  static func from(_ observable: ObservableWrapper<Element>) -> RxSwift.Observable<Element> {
    RxSwift.Observable<Element>.create { observer in
      let disposable = observable.subscribe(
        isThreadLocal: false,
        onError: { observer.onError($0.unwrapToError()) },
        onComplete: observer.onCompleted,
        onNext: observer.onNext)

      return Disposables.create(with: disposable.dispose)
    }
  }

  func asWrapper() -> ObservableWrapper<Element> {
    ObservableWrapper(inner: ObservableByEmitterKt.observable(onSubscribe: { emitter in
      let swiftDisposable = self.subscribe(
        onNext: { emitter.onNext(value: $0) },
        onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) },
        onCompleted: { emitter.onComplete() })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    }))
  }
}

extension RxSwift.Observable where Element == String {
  func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseList<T>>
    where T: KotlinBase
  {
    ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
      let swiftDisposable = self.subscribe(
        onNext: { jsonString in
          let result = ResponseParser.companion.fromList(jsonStr: jsonString, benSerializable: serial)
          guard let data = result.data
          else {
            emitter.onError(error: KotlinThrowable.wrapError(KTOError.JsonParseError))
            return
          }
          
          let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onNext(value: item)
        },
        onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }

  func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseItem<T>>
    where T: KotlinBase
  {
    ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
      let swiftDisposable = self.subscribe(
        onNext: { jsonString in
          let result = ResponseParser.companion.from(jsonStr: jsonString, benSerializable: serial)
          guard let data = result.data
          else {
            emitter.onError(error: KotlinThrowable.wrapError(KTOError.JsonParseError))
            return
          }
          
          let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onNext(value: item)
        },
        onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
}

// MARK: - Single

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
  public func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<Trait, Element> {
    let handler: (Swift.Error) throws -> PrimitiveSequence<Trait, Element> = { error in
      let e = transferLogic(error)
      return Single.error(e)
    }
    return self.catch(handler)
  }
}

extension RxSwift.Single where Element: AnyObject {
  static func from(_ single: SingleWrapper<Element>) -> RxSwift.Single<Element> {
    RxSwift.Single<Element>.create { observer in
      let disposable = single.subscribe(
        isThreadLocal: false,
        onError: { observer(.failure($0.unwrapToError())) },
        onSuccess: { observer(.success($0)) })

      return Disposables.create(with: disposable.dispose)
    }
  }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
  func asWrapper<T>() -> SingleWrapper<T> where T: Any {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self
        .subscribe(
          onSuccess: { emitter.onSuccess(value: $0) },
          onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })
      
      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == String {
  func asReaktiveResponseItem<T>() -> SingleWrapper<ResponseItem<T>> where T: Any {
    asReaktiveResponseItem(transfrom: { (result: T) -> T in result })
  }

  func asReaktiveResponseItem<T: Any, F: Any>(transfrom: @escaping ((T) -> F)) -> SingleWrapper<ResponseItem<F>> {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe(
        onSuccess: { jsonString in
          let json = JSON(parseJSON: jsonString)

          var item: ResponseItem<F>

          let value = json["data"].rawValue

          if
            let number = value as? NSNumber,
            number === kCFBooleanTrue ||
            number === kCFBooleanFalse
          {
            if
              let bool = json["data"].rawValue as? Bool,
              F.self == KotlinBoolean.self
            {
              item = .init(
                data: transfrom(KotlinBoolean(bool: bool) as! T),
                errorMsg: "",
                node: "",
                statusCode: "")
            }
            else {
              item = .init(
                data: transfrom(json["data"].rawValue as! T),
                errorMsg: "",
                node: "",
                statusCode: "")
            }
          }
          else {
            item = .init(
              data: transfrom(json["data"].rawValue as! T),
              errorMsg: "",
              node: "",
              statusCode: "")
          }

          emitter.onSuccess(value: item)
        },
        onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
  
  func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseItem<T>>
    where T: KotlinBase
  {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe(
        onSuccess: { jsonString in
          let result = ResponseParser.companion.from(jsonStr: jsonString, benSerializable: serial)
          guard let data = result.data
          else {
            emitter.onError(error: KotlinThrowable.wrapError(KTOError.JsonParseError))
            return
          }

          let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onSuccess(value: item)
        },
        onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
  
  func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponseList<T>>
    where T: KotlinBase
  {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe(
        onSuccess: { jsonString in
          let result = ResponseParser.companion.fromList(jsonStr: jsonString, benSerializable: serial)
          guard let data = result.data
          else {
            emitter.onError(error: KotlinThrowable.wrapError(KTOError.JsonParseError))
            return
          }
          
          let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onSuccess(value: item)
        },
        onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
  
  func asReaktiveResponsePayload<T>(serial: Kotlinx_serialization_coreKSerializer) -> SingleWrapper<ResponsePayload<T>>
    where T: KotlinBase
  {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe(
        onSuccess: { jsonString in
          let result = ResponseParser.companion.fromPayload(jsonStr: jsonString, benSerializable: serial)
          guard let data = result.data
          else {
            emitter.onError(error: KotlinThrowable.wrapError(KTOError.JsonParseError))
            return
          }
          
          let item = ResponsePayload(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onSuccess(value: item)
        },
        onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }

  func asReaktiveResponseNothing() -> SingleWrapper<sharedbu.Response<KotlinNothing>> {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self
        .subscribe(
          onSuccess: { jsonString in
            let result = ResponseParser.companion.fromNothing(jsonStr: jsonString)
            emitter.onSuccess(value: result)
          },
          onFailure: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
  
  func asReaktiveCompletable() -> CompletableWrapper {
    CompletableWrapper(inner: CompletableByEmitterKt.completable(onSubscribe: { emitter in
      let swiftDisposable = self.asCompletable()
        .subscribe(
          onCompleted: { emitter.onComplete() },
          onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    }))
  }
}

// MARK: - Completable

extension RxSwift.Completable {
  static func from(_ completable: CompletableWrapper) -> RxSwift.Completable {
    RxSwift.Completable.create { observer in
      let disposable = completable.subscribe(
        isThreadLocal: false,
        onError: { observer(.error($0.unwrapToError())) },
        onComplete: { observer(.completed) })

      return Disposables.create(with: disposable.dispose)
    }
  }
  
  func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<CompletableTrait, Swift.Never> {
    let handler: (Swift.Error) throws -> PrimitiveSequence<CompletableTrait, Swift.Never> = { error in
      let e = transferLogic(error)
      return Completable.error(e)
    }
    return self.catch(handler)
  }
}

// MARK: - Other

extension RxSwift.Maybe where Element: AnyObject {
  static func from(_ maybe: MaybeWrapper<Element>) -> RxSwift.Maybe<Element> {
    RxSwift.Maybe<Element>.create { observer in
      let disposable = maybe.subscribe(
        isThreadLocal: false,
        onError: { observer(.error($0.unwrapToError())) },
        onComplete: { observer(.completed) },
        onSuccess: { observer(.success($0)) })

      return Disposables.create(with: disposable.dispose)
    }
  }
}

extension RxCocoa.SharedSequenceConvertibleType where Element: AnyObject, SharingStrategy == DriverSharingStrategy {
  func toWrapper() -> ObservableWrapper<Element> {
    ObservableWrapper<Element>(
      inner: ObservableByEmitterKt
        .observable { emitter in
          let swiftDisposable = self.drive(onNext: { emitter.onNext(value: $0) })

          emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
        })
  }
}

class DisposableWrapper: sharedbu.Disposable {
  private var _disposable: Disposable
  var isDisposed = false

  init(disposable: Disposable) {
    _disposable = disposable
  }

  func dispose() {
    _disposable.dispose()
    isDisposed = true
  }
}
