import Foundation
import RxCocoa
import RxSwift

final class Pagination<T> {
  private let disposeBag = DisposeBag()

  private(set) var pageIndex = 1
  private(set) var startPageIndex = 0
  private(set) var offset = 1

  private var isLastData = false
  private var isRefreshing = false

  let refreshTrigger = PublishSubject<Void>()
  let loadNextPageTrigger = PublishSubject<Void>()
  let error = PublishSubject<Swift.Error>()
  let loading = BehaviorRelay<Bool>(value: false)
  let elements = BehaviorRelay<[T]>(value: [])

  init(
    pageIndex: Int = 1,
    offset: Int = 1,
    observable: @escaping ((Int) -> Observable<[T]>),
    onLoading: ((Bool) -> Void)? = nil,
    onElementChanged: (([T]) -> Void)? = nil)
  {
    self.offset = offset
    self.startPageIndex = pageIndex

    if let onLoading {
      loading
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: {
          onLoading($0)
        })
        .disposed(by: disposeBag)
    }

    if let onElementChanged {
      elements
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: {
          onElementChanged($0)
        })
        .disposed(by: disposeBag)
    }

    binding(observable)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - Binding

extension Pagination {
  private func binding(_ observable: @escaping (Int) -> Observable<[T]>) {
    let request = Observable
      .of(refreshRequest(), nextPageRequest())
      .merge()
      .share(replay: 1)

    let response = request
      .flatMap { [unowned self] page in
        if page > 1, self.isRefreshing {
          return Observable
            .concat((0..<page).map { observable($0 + 1) })
            .scan([T](), accumulator: { $0 + $1 })
            .takeLast(1)
        }
        else {
          return observable(page)
        }
      }
      .do(onNext: { [unowned self] in
        self.isLastData = $0.count == 0
      })
      .share(replay: 1)

    Observable
      .combineLatest(
        request,
        response,
        elements.asObservable())
      .map { [unowned self] _, response, elements in
        self.pageIndex == self.startPageIndex ? response : elements + response
      }
      .sample(response)
      .bind(to: elements)
      .disposed(by: disposeBag)

    Observable
      .of(
        request.map { _ in true },
        response.map { _ in false },
        error.map { _ in false })
      .merge()
      .bind(to: loading)
      .disposed(by: disposeBag)
  }

  private func refreshRequest() -> Observable<Int> {
    loading.asObservable()
      .sample(refreshTrigger)
      .flatMap { [unowned self] loading -> Observable<Int> in
        if loading {
          return Observable.empty()
        }
        else {
          self.isRefreshing = true

          if self.pageIndex < pageIndex {
            self.pageIndex = pageIndex
          }
          else {
            self.startPageIndex = self.pageIndex
          }

          return Observable<Int>.create { observer in
            observer.onNext(self.pageIndex)
            observer.onCompleted()
            return Disposables.create()
          }
        }
      }
  }

  private func nextPageRequest() -> Observable<Int> {
    loading.asObservable()
      .sample(loadNextPageTrigger)
      .flatMap { [unowned self] loading -> Observable<Int> in
        if loading || self.isLastData {
          return Observable.empty()
        }
        else {
          self.isRefreshing = false

          return Observable<Int>.create { observer in
            self.pageIndex += self.offset
            observer.onNext(self.pageIndex)
            observer.onCompleted()
            return Disposables.create()
          }
        }
      }
  }
}
