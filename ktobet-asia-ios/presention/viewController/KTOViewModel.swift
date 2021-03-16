//
//  KTOViewModel.swift
//  ktobet-asia-ios
//
//  Created by Leo Hsu on 2021/3/12.
//

import Foundation
import RxSwift
import RxCocoa

class KTOViewModel {
    private let _errors = PublishSubject<Error>.init()
    
    func errors() -> Observable<Error> {
        return _errors.throttle(.milliseconds(1500), latest: false, scheduler: MainScheduler.instance)
    }
    
    func applyObservableErrorHandle<T>() -> ObservableTransformer<T,T> {
        return ObservableTransformer { (observanle) -> Observable<T> in
            return observanle
                .do(onError: { [weak self] (e) in
                    self?._errors.onNext(e)
                }).catchError { _ in Observable.never() }
        }
    }
    
    func applySingleErrorHandler<T>() -> SingleTransformer<T,T> {
        return SingleTransformer { (single) -> Single<T> in
            return single
                .do(onError: { [weak self] (e) in
                    self?._errors.onNext(e)
                }).catchError { _ in Single.never() }
        }
    }
    
    func applyCompletableErrorHandler() -> CompletableTransformer {
        return CompletableTransformer { (completable) -> Completable in
            return completable.do(onError: { [weak self] (e) in
                self?._errors.onNext(e)
            }).catchError { _ in Completable.never() }
        }
    }
}
