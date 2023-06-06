import Foundation
import RxCocoa
import RxSwift

final class Pagination<T> {
  enum Mode {
    case refresh
    case loadNext
  }

  private let disposeBag = DisposeBag()

  private let startIndex: Int

  private var currentIndex: Int
  private var offset: Int
  private var mode = Mode.refresh

  private var isLastData = false

  let refreshTrigger = PublishSubject<Void>()
  let loadNextPageTrigger = PublishSubject<Void>()
  let error = PublishSubject<Swift.Error>()
  let loading = BehaviorRelay<Bool>(value: false)
  let elements = BehaviorRelay<[T]>(value: [])

  init(
    startIndex: Int,
    offset: Int,
    observable: @escaping ((Int) -> Observable<[T]>),
    onLoading: ((Bool) -> Void)? = nil,
    onElementChanged: (([T]) -> Void)? = nil)
  {
    self.offset = offset
    self.startIndex = startIndex
    self.currentIndex = startIndex

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
    Observable.merge(
      refreshRequest(),
      nextPageRequest())
      .do(onNext: { [unowned self] _ in
        self.loading.accept(true)
      })
      .flatMap { [unowned self] currentIndex in
        switch mode {
        case .refresh:
          return Observable
            .concat(queriedIndicesSoFar().map { observable($0) })
            .scan([T](), accumulator: { $0 + $1 })
            .takeLast(1)

        case .loadNext:
          return observable(currentIndex)
            .map {
              self.elements.value + $0
            }
        }
      }
      .do(onNext: { [unowned self] in
        self.loading.accept(false)
        self.isLastData = $0.count == 0
      })
      .bind(to: elements)
      .disposed(by: disposeBag)

    error
      .map { _ in false }
      .bind(to: loading)
      .disposed(by: disposeBag)
  }

  private func refreshRequest() -> Observable<Int> {
    refreshTrigger
      .flatMap { [unowned self] _ -> Observable<Int> in
        if self.loading.value {
          return Observable.empty()
        }
        else {
          self.mode = .refresh

          return Observable<Int>.create { observer in
            observer.onNext(self.currentIndex)
            observer.onCompleted()
            return Disposables.create()
          }
        }
      }
  }

  private func nextPageRequest() -> Observable<Int> {
    loadNextPageTrigger
      .flatMap { [unowned self] _ -> Observable<Int> in
        if self.loading.value || self.isLastData {
          return Observable.empty()
        }
        else {
          self.mode = .loadNext

          return Observable<Int>.create { observer in
            self.currentIndex += self.offset
            observer.onNext(self.currentIndex)
            observer.onCompleted()
            return Disposables.create()
          }
        }
      }
  }

  private func queriedIndicesSoFar() -> [Int] {
    var array = [Int]()
    for i in stride(from: startIndex, through: currentIndex, by: offset) {
      array.append(i)
    }

    return array
  }
}
