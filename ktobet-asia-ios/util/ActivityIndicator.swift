import RxSwift
import RxCocoa

extension ObservableType {
    public func trackActivity(_ activityIndicator: ActivityIndicator) -> RxSwift.Observable<Element> {
        activityIndicator.trackActivityOfObservable(self)
    }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
    public func trackActivity(_ activityIndicator: ActivityIndicator) -> RxSwift.Single<Element> {
        activityIndicator.trackActivityOfSingle(self)
    }
}

/**
Enables monitoring of sequence computation.

If there is at least one sequence computation in progress, `true` will be sent.
When all activities complete `false` will be sent.
*/
public class ActivityIndicator : SharedSequenceConvertibleType {
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

    fileprivate func trackActivityOfObservable
        <Source: ObservableConvertibleType>
        (_ source: Source)
        -> RxSwift.Observable<Source.Element>
    {
        .using {
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        } observableFactory: { token in
            return token.asObservable()
        }
    }

    fileprivate func trackActivityOfSingle
        <Source: PrimitiveSequenceType>
        (_ source: Source)
        -> RxSwift.Single<Source.Element>
        where Source.Trait == SingleTrait
    {
        .using {
            self.increment()
            return ActivityToken(source: source.primitiveSequence, disposeAction: self.decrement)
        } primitiveSequenceFactory: { token in
            return token.asSingle()
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

    public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        _loading
    }
}

// MARK: - ActivityToken

private extension ActivityIndicator {
    
    struct ActivityToken<T: ObservableConvertibleType>: Disposable {
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
    }
}

public extension Reactive where Base: UIButton {
    var throttledTap: ControlEvent<Void> {
        return ControlEvent<Void>(events: tap
            .throttle(.milliseconds(ContinuousTap.disableTapDuration), latest: false, scheduler: MainScheduler.instance))
    }
}

enum ContinuousTap {
    /// Disable Tap Duration in Milliseconds
    static let disableTapDuration: Int = 500
}
