import RxSwift

extension ObservableConvertibleType {
    func publish<Object: AnyObject, Value>(
        to object: Object,
        while condition: ((Value) -> Bool)? = nil,
        _ keyPath: ReferenceWritableKeyPath<Object, Value>)
        -> Observable<Element>
        where Element == Value
    {
        self.asObservable()
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak object] newValue in
                if let condition, condition(newValue) { return }
                object?[keyPath: keyPath] = newValue
            })
    }

    func publish<Object: AnyObject, Value>(
        to object: Object,
        while condition: ((Value) -> Bool)? = nil,
        _ keyPath: ReferenceWritableKeyPath<Object, Value?>)
        -> Observable<Element>
        where Element == Value
    {
        self.asObservable()
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak object] newValue in
                if let condition, condition(newValue) { return }
                object?[keyPath: keyPath] = newValue
            })
    }

    func collectError(to collectable: CollectErrorViewModel) -> Observable<Element> {
        self.asObservable()
            .observe(on: MainScheduler.instance)
            .do(onError: { [weak collectable] in
                collectable?.errorsSubject.onNext($0)
            })
    }
}

extension PrimitiveSequence where Trait == SingleTrait {
    func collectError(to collectable: CollectErrorViewModel) -> Single<Element> {
        self
            .observe(on: MainScheduler.instance)
            .do(onError: { [weak collectable] in
                collectable?.errorsSubject.onNext($0)
            })
    }
}

extension Completable {
    func complete<Object: AnyObject>(
        to object: Object,
        _ keyPath: ReferenceWritableKeyPath<Object, Bool>)
        -> Completable
    {
        self.observe(on: MainScheduler.instance)
            .do(onCompleted: { [weak object] in
                object?[keyPath: keyPath] = true
            })
    }
}
