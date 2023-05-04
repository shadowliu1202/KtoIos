import Foundation
import RxCocoa
import RxSwift
import SharedBu
import SwiftyJSON

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
  public func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<Trait, Element> {
    let handler: (Swift.Error) throws -> PrimitiveSequence<Trait, Element> = { error in
      let e = transferLogic(error)
      return Single.error(e)
    }
    return self.catch(handler)
  }
}

extension ObservableType {
  public func asDriverOnErrorJustComplete() -> Driver<Element> {
    asDriver { _ in
      Driver.empty()
    }
  }

  public func asDriverLogError(
    _ file: StaticString = #file,
    _ line: UInt = #line) -> SharedSequence<DriverSharingStrategy, Element>
  {
    asDriver(onErrorRecover: {
      Logger.shared.debug("Error: \($0) in file: \(file) atLine: \(line)")
      return .empty()
    })
  }
}

extension Completable {
  public func catchException(transferLogic: @escaping (Error) -> Error) -> PrimitiveSequence<CompletableTrait, Swift.Never> {
    let handler: (Swift.Error) throws -> PrimitiveSequence<CompletableTrait, Swift.Never> = { error in
      let e = transferLogic(error)
      return Completable.error(e)
    }
    return self.catch(handler)
  }
}

extension RxSwift.Observable where Element: AnyObject {
  static func from(_ observable: ObservableWrapper<Element>) -> RxSwift.Observable<Element> {
    RxSwift.Observable<Element>.create { observer in
      let disposable = observable.subscribe(
        isThreadLocal: false,
        onError: { observer.onError($0) },
        onComplete: observer.onCompleted,
        onNext: observer.onNext)

      return Disposables.create(with: disposable.dispose)
    }
  }

  func asWrapper() -> ObservableWrapper<Element> {
    ObservableWrapper(inner: ObservableByEmitterKt.observable(onSubscribe: { emitter in
      let swiftDisposable = self.subscribe(
        onNext: { element in
          emitter.onNext(value: element)
        },
        onError: { error in
          emitter.onError(error: ExceptionFactory.create(error))
        },
        onCompleted: {
          emitter.onComplete()
        })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    }))
  }
}

extension RxCocoa.SharedSequenceConvertibleType where Element: AnyObject, SharingStrategy == DriverSharingStrategy {
  func toWrapper() -> ObservableWrapper<Element> {
    ObservableWrapper<Element>(
      inner: ObservableByEmitterKt
        .observable { emitter in

          let swiftDisposable = self
            .drive(onNext: {
              emitter.onNext(value: $0)
            })

          emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
        })
  }
}

extension ObservableType where Element: Sequence {
  func forceCast<Element>(_: Element.Type) -> Observable<[Element]> {
    self.map {
      $0.compactMap { $0 as? Element }
    }
  }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == String {
  func asReaktiveCompletable() -> CompletableWrapper {
    CompletableWrapper(inner: CompletableByEmitterKt.completable(onSubscribe: { emitter in
      let swiftDisposable = self.createCompletableWithParsedError()
        .subscribe(
          onCompleted: {
            emitter.onComplete()
          },
          onError: { error in
            emitter.onError(error: ExceptionFactory.create(error))
          })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    }))
  }

  private func createCompletableWithParsedError() -> Completable {
    Completable.create { completable in
      self.subscribe(
        onSuccess: { jsonString in
          if let error = self.parseResponseToError(json: .init(parseJSON: jsonString)) {
            completable(.error(error))
          }
          else {
            completable(.completed)
          }
        },
        onFailure: { error in
          completable(.error(error))
        })
    }
  }

  func asReaktiveResponseNothing() -> SingleWrapper<SharedBu.Response<KotlinNothing>> {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self
        .subscribe(
          onSuccess: { jsonString in
            if let error = self.parseResponseToError(json: .init(parseJSON: jsonString)) {
              emitter.onError(error: ExceptionFactory.create(error))
            }
            else {
              let result = ResponseParser.companion.fromNothing(jsonStr: jsonString)
              emitter.onSuccess(value: result)
            }
          },
          onFailure: { error in
            emitter.onError(error: ExceptionFactory.create(error))
          })

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
          if let data = result.data {
            let item = ResponsePayload(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
            emitter.onSuccess(value: item)
          }
          else {
            let exception = ExceptionFactory.companion.create(
              message: result.errorMsg ?? "",
              statusCode: result.statusCode ?? "")
            emitter.onError(error: exception)
          }
        },
        onFailure: { error in
          emitter.onError(error: ExceptionFactory.create(error))
        })

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
          if let data = result.data {
            let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
            emitter.onSuccess(value: item)
          }
          else {
            let exception = ExceptionFactory.companion.create(
              message: result.errorMsg ?? "",
              statusCode: result.statusCode ?? "")
            emitter.onError(error: exception)
          }
        },
        onFailure: { error in
          emitter.onError(error: ExceptionFactory.create(error))
        })

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

          if let data = result.data {
            let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
            emitter.onSuccess(value: item)
          }
          else {
            let exception = ExceptionFactory.companion.create(
              message: result.errorMsg ?? "",
              statusCode: result.statusCode ?? "")
            emitter.onError(error: exception)
          }
        },
        onFailure: { error in
          emitter.onError(error: ExceptionFactory.create(error))
        })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }

  func asReaktiveResponseItem<T>() -> SingleWrapper<ResponseItem<T>> where T: Any {
    asReaktiveResponseItem(transfrom: { (result: T) -> T in result })
  }

  func asReaktiveResponseItem<T: Any, F: Any>(transfrom: @escaping ((T) -> F)) -> SingleWrapper<ResponseItem<F>> {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe(
        onSuccess: { jsonString in
          let json = JSON(parseJSON: jsonString)

          if let error = self.parseResponseToError(json: json) {
            emitter.onError(error: ExceptionFactory.create(error))
            return
          }

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
        onFailure: { error in
          emitter.onError(error: ExceptionFactory.create(error))
        })

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }

  private func parseResponseToError(json: JSON) -> Error? {
    if
      let statusCode = json["statusCode"].string,
      let errorMsg = json["errorMsg"].string,
      statusCode.count > 0,
      errorMsg.count > 0
    {
      return NSError(
        domain: "",
        code: Int(statusCode) ?? 0,
        userInfo: ["statusCode": statusCode, "errorMsg": errorMsg]) as Error
    }
    else {
      return nil
    }
  }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait, Element == NSArray {
  func asWrapper<T>() -> SingleWrapper<T> where T: Any {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe { array in
        emitter.onSuccess(value: array)
      } onFailure: { error in
        emitter.onError(error: ExceptionFactory.create(error))
      }
      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
  func asWrapper<T>() -> SingleWrapper<T> where T: Any {
    SingleWrapper(inner: SingleByEmitterKt.single { emitter in
      let swiftDisposable = self.subscribe { element in
        emitter.onSuccess(value: element)
      } onFailure: { error in
        emitter.onError(error: ExceptionFactory.create(error))
      }
      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
}

extension RxSwift.Observable where Element == String {
  func asReaktiveResponseList<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseList<T>>
    where T: KotlinBase
  {
    ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
      let swiftDisposable = self.subscribe { jsonString in
        let result = ResponseParser.companion.fromList(jsonStr: jsonString, benSerializable: serial)
        if let data = result.data {
          let item = ResponseList(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onNext(value: item)
        }
        else {
          let exception = ExceptionFactory.companion.create(
            message: result.errorMsg ?? "",
            statusCode: result.statusCode ?? "")
          emitter.onError(error: exception)
        }
      } onError: { error in
        emitter.onError(error: ExceptionFactory.create(error))
      }

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }

  func asReaktiveResponseItem<T>(serial: Kotlinx_serialization_coreKSerializer) -> ObservableWrapper<ResponseItem<T>>
    where T: KotlinBase
  {
    ObservableWrapper(inner: ObservableByEmitterKt.observable { emitter in
      let swiftDisposable = self.subscribe { jsonString in
        let result = ResponseParser.companion.from(jsonStr: jsonString, benSerializable: serial)
        if let data = result.data {
          let item = ResponseItem(data: data, errorMsg: "", node: "", statusCode: result.statusCode ?? "")
          emitter.onNext(value: item)
        }
        else {
          let exception = ExceptionFactory.companion.create(
            message: result.errorMsg ?? "",
            statusCode: result.statusCode ?? "")
          emitter.onError(error: exception)
        }
      } onError: { error in
        emitter.onError(error: ExceptionFactory.create(error))
      }

      emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
    })
  }
}

extension RxSwift.Single where Element: AnyObject {
  static func from(_ single: SingleWrapper<Element>) -> RxSwift.Single<Element> {
    RxSwift.Single<Element>.create { observer in
      let disposable = single.subscribe(
        isThreadLocal: false,
        onError: { observer(.failure($0)) },
        onSuccess: { observer(.success($0)) })

      return Disposables.create(with: disposable.dispose)
    }
  }
}

extension RxSwift.Maybe where Element: AnyObject {
  static func from(_ maybe: MaybeWrapper<Element>) -> RxSwift.Maybe<Element> {
    RxSwift.Maybe<Element>.create { observer in
      let disposable = maybe.subscribe(
        isThreadLocal: false,
        onError: { observer(.error($0)) },
        onComplete: { observer(.completed) },
        onSuccess: { observer(.success($0)) })

      return Disposables.create(with: disposable.dispose)
    }
  }
}

extension RxSwift.Completable {
  static func from(_ completable: CompletableWrapper) -> RxSwift.Completable {
    RxSwift.Completable.create { observer in
      let disposable = completable.subscribe(
        isThreadLocal: false,
        onError: { observer(.error($0)) },
        onComplete: { observer(.completed) })

      return Disposables.create(with: disposable.dispose)
    }
  }
}

class DisposableWrapper: SharedBu.Disposable {
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
