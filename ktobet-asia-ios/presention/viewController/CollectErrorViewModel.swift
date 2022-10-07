import Foundation
import RxSwift
import RxCocoa

protocol CollectErrorViewModelProtocol {
    func errors() -> Observable<Error>
    func applyObservableErrorHandle<T>() -> ObservableTransformer<T,T>
    func applySingleErrorHandler<T>() -> SingleTransformer<T,T>
    func applyCompletableErrorHandler() -> CompletableTransformer
}

extension CollectErrorViewModelProtocol {
    func errors() -> Observable<Error> {
        return Observable<Error>.never()
    }
    
    func applyObservableErrorHandle<T>() -> ObservableTransformer<T,T> {
        return ObservableTransformer.init { observable in
            return observable
        }
    }
    
    func applySingleErrorHandler<T>() -> SingleTransformer<T,T> {
        return SingleTransformer.init { single in
            return single
        }
    }
    
    func applyCompletableErrorHandler() -> CompletableTransformer {
        return CompletableTransformer.init { completable in
            return completable
        }
    }
}

class CollectErrorViewModel: CollectErrorViewModelProtocol {
    private let _errors = PublishSubject<Error>.init()
    
    func errors() -> Observable<Error> {
        return _errors.throttle(.milliseconds(1500), latest: false, scheduler: MainScheduler.instance)
    }
    
    func applyObservableErrorHandle<T>() -> ObservableTransformer<T,T> {
        return ObservableTransformer { (observanle) -> Observable<T> in
            return observanle
                .do(onError: { [weak self] (e) in
                    self?._errors.onNext(e)
                }).catch { _ in Observable.never() }
        }
    }
    
    func applySingleErrorHandler<T>() -> SingleTransformer<T,T> {
        return SingleTransformer { (single) -> Single<T> in
            return single
                .do(onError: { [weak self] (e) in
                    self?._errors.onNext(e)
                }).catch { _ in Single.never() }
        }
    }
    
    func applyCompletableErrorHandler() -> CompletableTransformer {
        return CompletableTransformer { (completable) -> Completable in
            return completable.do(onError: { [weak self] (e) in
                self?._errors.onNext(e)
            }).catch { _ in Completable.never() }
        }
    }
}
