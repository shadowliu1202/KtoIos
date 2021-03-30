import Foundation
import RxSwift
import RxCocoa

class Pagination<T> {
    let refreshTrigger = PublishSubject<Void>()
    let loadNextPageTrigger = PublishSubject<Void>()
    let error = PublishSubject<Swift.Error>()
    let loading = BehaviorRelay<Bool>(value: false)
    let elements = BehaviorRelay<[T]>(value: [])
    var pageIndex: Int = 1
    var isLastData = false
    private let disposeBag = DisposeBag()
    
    init(callBack: @escaping ((Int) -> Observable<[T]>)) {
        let refreshRequest = loading.asObservable()
            .sample(refreshTrigger)
            .flatMap { loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                } else {
                    self.pageIndex = 1
                    return Observable<Int>.create { observer in
                        observer.onNext(self.pageIndex)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
            }
        
        let nextPageRequest = loading.asObservable()
            .sample(loadNextPageTrigger)
            .flatMap { loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                } else if self.isLastData {
                    return Observable.empty()
                } else {
                    return Observable<Int>.create {  observer in
                        self.pageIndex += 1
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
        
        let response = request.flatMap { page -> Observable<[T]> in
            callBack(page)
        }.share(replay: 1)
        
        Observable.combineLatest(request, response, elements.asObservable()) { request, response, elements in
            return self.pageIndex == 1 ? response : elements + response
        }
        .sample(response)
        .bind(to: elements)
        .disposed(by: disposeBag)
                
        Observable.of(request.map({ (response) -> Bool in
            return true
        }),
        response.map({ (response) -> Bool in
            self.isLastData = response.count == 0
            return false
        }),
        error.map({ (error) -> Bool in
            return false
        }))
        .merge()
        .bind(to: loading)
        .disposed(by: disposeBag)
    }
}
