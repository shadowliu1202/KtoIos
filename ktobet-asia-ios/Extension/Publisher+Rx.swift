import Combine
import RxCocoa
import RxSwift

extension Publisher {
  func asObservable(scheduler: some Scheduler = RunLoop.main) -> Observable<Output> {
    Observable<Output>.create { observer in
      let cancel = self
        .receive(on: scheduler)
        .sink(
          receiveCompletion: { completion in
            switch completion {
            case .finished:
              observer.onCompleted()
            case .failure(let error):
              observer.onError(error)
            }
          },
          receiveValue: { value in
            observer.onNext(value)
          })

      return Disposables.create { cancel.cancel() }
    }
  }

  func asDriver() -> Driver<Output> {
    self
      .receive(on: RunLoop.main)
      .asObservable()
      .asDriverOnErrorJustComplete()
  }

  func skipOneThenAsDriver() -> Driver<Output> {
    self
      .dropFirst()
      .receive(on: RunLoop.main)
      .asObservable()
      .asDriverOnErrorJustComplete()
  }
}
