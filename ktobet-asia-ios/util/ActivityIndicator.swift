import RxSwift
import RxCocoa

extension ObservableConvertibleType {
    public func trackActivity(_ activityIndicator: ActivityIndicator) -> RxSwift.Observable<Element> {
        activityIndicator.trackActivityOfObservable(self)
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

    public init() {
        _loading = _relay.asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    fileprivate func trackActivityOfObservable<Source: ObservableConvertibleType>(_ source: Source) -> RxSwift.Observable<Source.Element> {
        return RxSwift.Observable.using({ () -> ActivityToken<Source.Element> in
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }) { t in
            return t.asObservable()
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
    
    private struct ActivityToken<E> : ObservableConvertibleType, Disposable {
        private let _source: Observable<E>
        private let _dispose: Cancelable

        init(source: Observable<E>, disposeAction: @escaping () -> Void) {
            _source = source
            _dispose = Disposables.create(with: disposeAction)
        }

        func dispose() {
            _dispose.dispose()
        }

        func asObservable() -> Observable<E> {
            _source
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
