import Foundation
import RxSwift
import RxCocoa

class Pagination<T> {
    private let disposeBag = DisposeBag()
    
    let refreshTrigger = PublishSubject<Void>()
    let loadNextPageTrigger = PublishSubject<Void>()
    let error = PublishSubject<Swift.Error>()
    let loading = BehaviorRelay<Bool>(value: false)
    let elements = BehaviorRelay<[T]>(value: [])
    
    var pageIndex: Int = 1
    var startPageIndex: Int = 0
    var offset: Int = 1
    var isLastData = false
    
    var onElementChanged: (([T]) -> Void)?
    
    init(
        pageIndex: Int = 1,
        offset: Int = 1,
        observable: @escaping ((Int) -> Observable<[T]>),
        onElementChanged: (([T]) -> Void)? = nil
    ) {
        self.offset = offset
        self.startPageIndex = pageIndex
        self.onElementChanged = onElementChanged
        
        elements
            .subscribe(onNext: { [unowned self] in
                self.onElementChanged?($0)
            })
            .disposed(by: disposeBag)
        
        let refreshRequest = loading.asObservable()
            .sample(refreshTrigger)
            .flatMap { [unowned self] loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                }
                else {
                    self.pageIndex = pageIndex
                    return Observable<Int>.create { observer in
                        observer.onNext(self.pageIndex)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
            }
        
        let nextPageRequest = loading.asObservable()
            .sample(loadNextPageTrigger)
            .flatMap { [unowned self] loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                }
                else if self.isLastData {
                    return Observable.empty()
                }
                else {
                    return Observable<Int>.create { observer in
                        self.pageIndex += self.offset
                        observer.onNext(self.pageIndex)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
            }
        
        let request = Observable
            .of(refreshRequest, nextPageRequest)
            .merge()
            .share(replay: 1)
        
        let response = request
            .flatMap { page -> Observable<[T]> in
                observable(page)
            }
            .share(replay: 1)
        
        Observable
            .combineLatest(
                request,
                response,
                elements.asObservable()
            )
            .map { [unowned self] request, response, elements in
                return self.pageIndex == self.startPageIndex ? response : elements + response
            }
            .sample(response)
            .bind(to: elements)
            .disposed(by: disposeBag)
        
        Observable
            .of(
                request.map({ (response) -> Bool in
                    return true
                }),
                response.map({ [unowned self] (response) -> Bool in
                    self.isLastData = response.count == 0
                    return false
                }),
                error.map({ (error) -> Bool in
                    return false
                })
            )
            .merge()
            .bind(to: loading)
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
