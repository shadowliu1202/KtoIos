import Foundation
import RxSwift
import RxCocoa
import SharedBu


class P2PViewModel: CollectErrorViewModel,
                    ProductWebGameViewModelProtocol {
    @Injected private var loading: Loading
  
    private (set) var refreshTrigger = BehaviorSubject<Void>(value: ())
    
    private let gameSubject = PublishSubject<[P2PGame]>()
    
    private let webGameResultSubject: PublishSubject<WebGameResult> = .init()

    private var p2pUseCase: P2PUseCase!
    
    private var productName: String! = "p2p"
    
    private var disposeBag = DisposeBag()
    
    var loadingTracker: ActivityIndicator { loading.tracker }
    
    var webGameResultDriver: Driver<WebGameResult> {
        webGameResultSubject.asDriverLogError()
    }
    
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
    
    func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
        p2pUseCase.checkBonusAndCreateGame(game)
    }
    
    func fetchGame(_ game: WebGame) {
        configFetchGame(
            game,
            resultSubject: webGameResultSubject,
            errorSubject: errorsSubject
        )
        .disposed(by: disposeBag)
    }
}

// MARK: - Data Handle

extension P2PViewModel {
    
    var dataSource: Observable<[P2PGame]> {
        gameSubject
            .catchAndReturn([])
            .share(replay: 1)
    }
    
    func getGameProduct() -> String {
        productName
    }
    
    func getGameProductType() -> ProductType {
        ProductType.p2p
    }
}
