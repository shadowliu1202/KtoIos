import Foundation
import RxSwift
import RxCocoa
import SharedBu


class ArcadeViewModel: KTOViewModel {
    private let arcadeUseCase: ArcadeUseCase
    private let memoryCache: MemoryCacheImpl
    private let arcadeAppService: IArcadeAppService
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    private var disposeBag = DisposeBag()
    private lazy var gameTags = RxSwift.Single<ArcadeDTO.GameTags>.from(arcadeAppService.getTags()).asObservable()
    private var recommendFilter = BehaviorRelay<Bool>(value: false)
    private var newFilter = BehaviorRelay<Bool>(value: false)
    private lazy var filterSets: Observable<(Bool, Bool)> = Observable.combineLatest(recommendFilter, newFilter) { ($0, $1) }
    
    lazy var tagStates: Observable<((ProductDTO.RecommendTag? , Bool), (ProductDTO.NewTag? , Bool))> = Observable.combineLatest(recommendFilter, newFilter, gameTags).map({ (isRecommend, isNew , gameTags) in
        return ((gameTags.recommendTag, isRecommend), (gameTags.newTag, isNew))
    }).compose(applyObservableErrorHandle())
           
    func selectAll() {
        recommendFilter.accept(false)
        newFilter.accept(false)
        setCache(isRecommend: false, isNew: false)
    }
    
    func toggleRecommend() {
        let value = !recommendFilter.value
        recommendFilter.accept(value)
        setCache(isRecommend: value)
    }
    
    func toggleNew() {
        let value = !newFilter.value
        newFilter.accept(value)
        setCache(isNew: value)
    }
    
    private func setCache(isRecommend: Bool? = nil, isNew: Bool? = nil) {
        let filters: [GameFilter] = memoryCache.getGameTag(.arcadeGameTag) ?? []
        var recommend: Bool
        if isRecommend == nil {
            recommend = filters.contains(GameFilter.Promote.init())
        } else {
            recommend = isRecommend!
        }
        var new: Bool
        if isNew == nil {
            new = filters.contains(GameFilter.New.init())
        } else {
            new = isNew!
        }
        var gameFilters: [GameFilter] = []
        if(recommend) { gameFilters.append(GameFilter.Promote.init()) }
        if(new) { gameFilters.append(GameFilter.New.init()) }
        memoryCache.setGameTag(.arcadeGameTag, gameFilters)
    }
    
    lazy var gameSource = filterSets.flatMapLatest({
        return self.arcadeUseCase.getGames(isRecommend: $0.0, isNew: $0.1).compose(self.applyObservableErrorHandle()).catchError { error in
            return Observable.error(error)
        }.retry()
    })
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    
    init(arcadeUseCase: ArcadeUseCase, memoryCache: MemoryCacheImpl, arcadeAppService: IArcadeAppService) {
        self.arcadeUseCase = arcadeUseCase
        self.memoryCache = memoryCache
        self.arcadeAppService = arcadeAppService
        super.init()
        if let tags: [GameFilter] = memoryCache.getGameTag(.arcadeGameTag) {
            if tags.contains(GameFilter.New.init()) {
                newFilter.accept(true)
            }
            if tags.contains(GameFilter.Promote.init()) {
                recommendFilter.accept(true)
            }
        }
    }
    
    private func addFavorite(_ game: WebGameWithDuplicatable) -> Completable {
        return arcadeUseCase.addFavorite(game: game)
    }
    
    private func removeFavorite(_ game: WebGameWithDuplicatable) -> Completable {
        return arcadeUseCase.removeFavorite(game: game)
    }
}

extension ArcadeViewModel: ProductViewModel {
    func getFavorites() {
        favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
        arcadeUseCase.getFavorites().subscribe(onNext: { [weak self] (games) in
            guard let games = games as? [ArcadeGame] else { return }
            if games.count > 0 {
                self?.favorites.onNext(games)
            } else {
                self?.favorites.onError(KTOError.EmptyData)
            }
        }, onError: { [weak self] (e) in
            self?.favorites.onError(e)
        }).disposed(by: disposeBag)
    }
    
    func getGameProductType() -> ProductType {
        ProductType.arcade
    }
    
    func favoriteProducts() -> Observable<[WebGameWithDuplicatable]> {
        return favorites.asObservable()
    }
    
    func toggleFavorite(game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction) -> (), onError: @escaping (Error) -> ()) {
        if game.isFavorite {
            removeFavorite(game).subscribe(onCompleted: {
                onCompleted(.remove)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        } else {
            addFavorite(game).subscribe(onCompleted: {
                onCompleted(.add)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        }
    }
    
    func getGameProduct() -> String { "arcade" }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return arcadeUseCase.createGame(gameId: gameId)
    }
    
    func clearSearchResult() {
        triggerSearch("")
    }
    
    func searchSuggestion() -> Single<[String]> {
        return arcadeUseCase.getSuggestKeywords()
    }
    
    func triggerSearch(_ text: String?) {
        guard let keyword = text else { return }
        self.searchKey.accept(SearchKeyword(keyword: keyword))
    }
    
    func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
        return self.searchKey.flatMapLatest { [unowned self] (keyword) -> Observable<Event<[WebGameWithDuplicatable]>> in
            return self.arcadeUseCase.searchGames(keyword: keyword).materialize()
        }
    }
}
