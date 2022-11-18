import Foundation
import RxSwift
import RxCocoa
import SharedBu


class P2PViewModel: CollectErrorViewModel {
    private (set) var refreshTrigger = BehaviorSubject<Void>(value: ())
    
    private let gameSubject = PublishSubject<[P2PGame]>()
    
    private var p2pUseCase: P2PUseCase!
    
    private var productName: String! = "p2p"
    
    private var disposeBag = DisposeBag()
    
    init(p2pUseCase: P2PUseCase) {
        super.init()
        
        self.p2pUseCase = p2pUseCase
        
        refreshTrigger
            .flatMapLatest { [unowned self] in
                self.getAllGames().asObservable()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
}

// MARK: - API

extension P2PViewModel {
    
    func getTurnOverStatus() -> Single<P2PTurnOver> {
        p2pUseCase
            .getTurnOverStatus()
            .compose(applySingleErrorHandler())
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        p2pUseCase
            .getAllGames()
            .do(onSuccess: { [unowned self] in
                self.productName = $0.first?.productName
                self.gameSubject.onNext($0)
            })
            .compose(applySingleErrorHandler())
    }
}

// MARK: - Data Handle

extension P2PViewModel {
    
    var dataSource: Observable<[P2PGame]> {
        gameSubject
            .catchAndReturn([])
            .share(replay: 1)
    }
}

// MARK: - ProductWebGameViewModelProtocol

extension P2PViewModel: ProductWebGameViewModelProtocol {
    
    func getGameProduct() -> String {
        productName
    }
    
    func getGameProductType() -> ProductType {
        ProductType.p2p
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        p2pUseCase.createGame(gameId: gameId)
    }
}
