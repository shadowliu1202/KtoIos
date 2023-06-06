import RxCocoa
import RxSwift

extension ObservableType {
  func trackOnDispose(_ activityIndicator: ActivityIndicator) -> RxSwift.Observable<Element> {
    activityIndicator.trackOnDisposeOfObservable(self)
  }

  func trackOnNext(
    _ activityIndicator: ActivityIndicator,
    resetWhenSubscribe: Bool = true)
    -> RxSwift.Observable<Element>
  {
    activityIndicator.trackOnNext(self, resetWhenSubscribe: resetWhenSubscribe)
  }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
  func trackOnDispose(_ activityIndicator: ActivityIndicator) -> RxSwift.Single<Element> {
    activityIndicator.trackOnDisposeOfSingle(self)
  }
}

extension PrimitiveSequenceType where Trait == CompletableTrait {
  func trackOnDispose(_ activityIndicator: ActivityIndicator) -> RxSwift.Completable {
    activityIndicator.trackOnDisposeOfCompletable(self)
  }
}

/// Enables monitoring of sequence computation.
///
/// If there is at least one sequence computation in progress, `true` will be sent.
/// When all activities complete `false` will be sent.
public class ActivityIndicator: SharedSequenceConvertibleType {
  public typealias Element = Bool
  public typealias SharingStrategy = DriverSharingStrategy

  private let _lock = NSRecursiveLock()
  private let _relay = BehaviorRelay(value: 0)
  private let _loading: SharedSequence<SharingStrategy, Bool>

  var isLoading: Bool {
    _relay.value > 0
  }

  public init() {
    _loading = _relay.asDriver()
      .map { $0 > 0 }
      .distinctUntilChanged()
  }

  fileprivate func trackOnNext
  <Source: ObservableType>
  (_ source: Source, resetWhenSubscribe: Bool)
    -> RxSwift.Observable<Source.Element>
  {
    source
      .do(
        onNext: { _ in
          self.decrement()
        },
        onSubscribe: {
          if !self.isLoading, resetWhenSubscribe {
            self.set(1)
          }
          else {
            self.increment()
          }
        },
        onDispose: { self.decrement() })
  }

  fileprivate func trackOnDisposeOfObservable
  <Source: ObservableConvertibleType>
  (_ source: Source)
    -> RxSwift.Observable<Source.Element>
  {
    .using {
      self.increment()
      return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
    } observableFactory: { token in
      token.asObservable()
    }
  }

  fileprivate func trackOnDisposeOfSingle
  <Source: PrimitiveSequenceType>
  (_ source: Source)
    -> RxSwift.Single<Source.Element>
    where Source.Trait == SingleTrait
  {
    .using {
      self.increment()
      return ActivityToken(source: source.primitiveSequence, disposeAction: self.decrement)
    } primitiveSequenceFactory: { token in
      token.asSingle()
    }
  }

  fileprivate func trackOnDisposeOfCompletable
  <Source: PrimitiveSequenceType>
  (_ source: Source) -> RxSwift.Completable
    where Source.Trait == CompletableTrait
  {
    .using {
      self.increment()
      return ActivityToken(source: source.primitiveSequence, disposeAction: self.decrement)
    } primitiveSequenceFactory: { token in
      token.asCompletable()
    }
  }

  private func increment() {
    _lock.lock()
    _relay.accept(_relay.value + 1)
    _lock.unlock()
  }

  private func decrement() {
    _lock.lock()
    _relay.accept(_relay.value - 1)
    _lock.unlock()
  }

  private func set(_ value: Int) {
    _lock.lock()
    _relay.accept(value)
    _lock.unlock()
  }

  public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
    _loading
  }
}

// MARK: - ActivityToken

extension ActivityIndicator {
  fileprivate struct ActivityToken<T: ObservableConvertibleType>: Disposable {
    private let _source: T
    private let _dispose: Cancelable

    init(source: T, disposeAction: @escaping () -> Void) {
      _source = source
      _dispose = Disposables.create(with: disposeAction)
    }

    func dispose() {
      _dispose.dispose()
    }

    func asObservable() -> Observable<T.Element> {
      _source.asObservable()
    }

    func asSingle() -> Single<T.Element> {
      guard let single = _source as? Single<T.Element>
      else { fatalError("The source is not a single type, consider to use asObservable") }
      return single
    }

    func asCompletable() -> Completable {
      guard let completable = _source as? Completable
      else { fatalError("The source is not a completable type, consider to use asObservable") }
      return completable
    }
  }
}

extension Reactive where Base: UIButton {
  public var throttledTap: ControlEvent<Void> {
    ControlEvent<Void>(
      events: tap
        .throttle(.milliseconds(ContinuousTap.disableTapDuration), latest: false, scheduler: MainScheduler.instance))
  }
}

enum ContinuousTap {
  /// Disable Tap Duration in Milliseconds
  static let disableTapDuration = 500
}
