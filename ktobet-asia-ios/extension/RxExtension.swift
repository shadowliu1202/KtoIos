//
//  RxExtension.swift
//  ktobet-asia-ios
//
//  Created by Leo Hsu on 2021/3/11.
//

import RxSwift
import RxCocoa

///reference: https://gist.github.com/sgr-ksmt/c05cc1cf41a32b8b77e277394c29509a
struct ObservableTransformer<T, R> {
    let transformer: (Observable<T>) -> Observable<R>
    init(transformer: @escaping (Observable<T>) -> Observable<R>) {
        self.transformer = transformer
    }
    
    func call(_ observable: Observable<T>) -> Observable<R> {
        return transformer(observable)
    }
}

extension ObservableType {
    func compose<T>(_ transformer: ObservableTransformer<Element, T>) -> Observable<T> {
        return transformer.call(self.asObservable())
    }
    ///reference: https://github.com/ReactiveX/RxSwift/blob/c4e4c1bd1c098ab942f0dc42b4fd66ab62e1bf9e/RxSwift/Observables/WithUnretained.swift
    /**
     Provides an unretained, safe to use (i.e. not implicitly unwrapped), reference to an object along with the events emitted by the sequence.
     
     In the case the provided object cannot be retained successfully, the seqeunce will complete.
     
     - note: Be careful when using this operator in a sequence that has a buffer or replay, for example `share(replay: 1)`, as the sharing buffer will also include the provided object, which could potentially cause a retain cycle.
     
     - parameter obj: The object to provide an unretained reference on.
     - parameter resultSelector: A function to combine the unretained referenced on `obj` and the value of the observable sequence.
     - returns: An observable sequence that contains the result of `resultSelector` being called with an unretained reference on `obj` and the values of the original sequence.
     */
    public func withUnretained<Object: AnyObject, Out>(
        _ obj: Object,
        resultSelector: @escaping (Object, Element) -> Out
    ) -> RxSwift.Observable<Out> {
        map { [weak obj] element -> Out in
            guard let obj = obj else { throw UnretainedError.failedRetaining }

            return resultSelector(obj, element)
        }
        .catchError{ error -> RxSwift.Observable<Out> in
            guard let unretainedError = error as? UnretainedError,
                  unretainedError == .failedRetaining else {
                return .error(error)
            }

            return .empty()
        }
    }

    
    /**
     Provides an unretained, safe to use (i.e. not implicitly unwrapped), reference to an object along with the events emitted by the sequence.
     
     In the case the provided object cannot be retained successfully, the seqeunce will complete.
     
     - note: Be careful when using this operator in a sequence that has a buffer or replay, for example `share(replay: 1)`, as the sharing buffer will also include the provided object, which could potentially cause a retain cycle.
     
     - parameter obj: The object to provide an unretained reference on.
     - returns: An observable sequence of tuples that contains both an unretained reference on `obj` and the values of the original sequence.
     */
    public func withUnretained<Object: AnyObject>(_ obj: Object) -> RxSwift.Observable<(Object, Element)> {
        return withUnretained(obj) { ($0, $1) }
    }
}

struct SingleTransformer<T, R> {
    let transformer: (Single<T>) -> Single<R>
    init(transformer: @escaping (Single<T>) -> Single<R>) {
        self.transformer = transformer
    }
    
    func call(_ single: Single<T>) -> Single<R> {
        return transformer(single)
    }
}

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
    func compose<T>(_ transformer: SingleTransformer<Element, T>) -> Single<T> {
        return transformer.call(self)
    }
}

struct CompletableTransformer {
    let transformer: (Completable) -> Completable
    init(transformer: @escaping (Completable) -> Completable) {
        self.transformer = transformer
    }
    
    func call(_ completable: Completable) -> Completable {
        return transformer(completable)
    }
}

extension Completable {
    func compose(_ transformer: CompletableTransformer) -> Completable {
        return transformer.call(self)
    }
}

private enum UnretainedError: Swift.Error {
    case failedRetaining
}
