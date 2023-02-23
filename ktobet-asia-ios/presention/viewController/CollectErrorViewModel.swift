import Foundation
import RxCocoa
import RxSwift

protocol CollectErrorViewModelProtocol {
  func errors() -> Observable<Error>
  func applyObservableErrorHandle<T>() -> ObservableTransformer<T, T>
  func applySingleErrorHandler<T>() -> SingleTransformer<T, T>
  func applyCompletableErrorHandler() -> CompletableTransformer
}

extension CollectErrorViewModelProtocol {
  func errors() -> Observable<Error> {
    Observable<Error>.never()
  }

  func applyObservableErrorHandle<T>() -> ObservableTransformer<T, T> {
    ObservableTransformer.init { observable in
      observable
    }
  }

  func applySingleErrorHandler<T>() -> SingleTransformer<T, T> {
    SingleTransformer.init { single in
      single
    }
  }

  func applyCompletableErrorHandler() -> CompletableTransformer {
    CompletableTransformer.init { completable in
      completable
    }
  }
}

class CollectErrorViewModel: CollectErrorViewModelProtocol {
  let errorsSubject = PublishSubject<Error>.init()

  func errors() -> Observable<Error> {
    errorsSubject.throttle(.milliseconds(1500), latest: false, scheduler: MainScheduler.instance)
  }

  func applyObservableErrorHandle<T>() -> ObservableTransformer<T, T> {
    ObservableTransformer { observanle -> Observable<T> in
      observanle
        .do(onError: { [weak self] e in
          self?.errorsSubject.onNext(e)
        }).catch { _ in Observable.never() }
    }
  }

  func applySingleErrorHandler<T>() -> SingleTransformer<T, T> {
    SingleTransformer { single -> Single<T> in
      single
        .do(onError: { [weak self] e in
          self?.errorsSubject.onNext(e)
        }).catch { _ in Single.never() }
    }
  }

  func applyCompletableErrorHandler() -> CompletableTransformer {
    CompletableTransformer { completable -> Completable in
      completable.do(onError: { [weak self] e in
        self?.errorsSubject.onNext(e)
      }).catch { _ in Completable.never() }
    }
  }
}
