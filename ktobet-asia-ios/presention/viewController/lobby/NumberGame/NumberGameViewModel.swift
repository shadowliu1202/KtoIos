import Foundation
import RxSwift
import RxCocoa
import SharedBu

class NumberGameViewModel: CollectErrorViewModel {
    private let numberGameUseCase: NumberGameUseCase
    private let memoryCache: MemoryCacheImpl
    private let numberGameService: INumberGameAppService
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    private var disposeBag = DisposeBag()
    private lazy var filterSets: Observable<Set<GameFilter>> = Observable.combineLatest(tagFilter, recommendFilter, newFilter) { (tags, recommand, new) -> Set<GameFilter> in
        var gameFilters: Set<GameFilter> = Set(tags.map({
            GameFilter.Tag.init(tag: GameTag.init(type: $0.id, name: $0.name))
        }))
        if recommand { gameFilters.insert(GameFilter.Promote.init()) }
        if new { gameFilters.insert(GameFilter.New.init()) }
        return gameFilters
    }
    
    lazy var popularGames = numberGameUseCase.getPopularGames()
    lazy var allGames = Observable.combineLatest(gameSorting, filterSets).flatMapLatest { (gameSorting, gameFilters) ->  Observable<[NumberGame]> in
        return self.numberGameUseCase.getGames(order: gameSorting, tags: gameFilters).compose(self.applyObservableErrorHandle()).catchError { error in
            return Observable.error(error)
        }.retry()
    }
    
    private lazy var gameTags = RxSwift.Single<NumberGameDTO.GameTags>.from(numberGameService.getTags()).asObservable()
    private var tagFilter = BehaviorRelay<[ProductDTO.GameTag]>(value: [])
    private var recommendFilter = BehaviorRelay<Bool>(value: false)
    private var newFilter = BehaviorRelay<Bool>(value: false)
    
    lazy var tagStates: Observable<((ProductDTO.RecommendTag? , Bool), (ProductDTO.NewTag? , Bool), [(ProductDTO.GameTag, Bool)])> = Observable.combineLatest(tagFilter, recommendFilter, newFilter, gameTags).map({ (filter, isRecommend, isNew , gameTags) in
        return ((gameTags.recommendTag, isRecommend), (gameTags.newTag, isNew), gameTags.gameTags.map({ ($0, filter.contains($0)) }))
    }).compose(applyObservableErrorHandle())
    
    func selectAll() {
        tagFilter.accept([])
        recommendFilter.accept(false)
        newFilter.accept(false)
        updateGameSorting()
        setCache(isRecommend: false, isNew: false, gameTags: [])
    }
    
    func toggleRecommend() {
        let value = !recommendFilter.value
        recommendFilter.accept(value)
        updateGameSorting()
        setCache(isRecommend: value)
    }
    
    func toggleNew() {
        let value = !newFilter.value
        newFilter.accept(value)
        updateGameSorting()
        setCache(isNew: value)
    }
    
    func toggleTag(_ tag: ProductDTO.GameTag) {
        var copyValue = tagFilter.value
        if let index = copyValue.firstIndex(of: tag) {
            copyValue.remove(at: index)
        } else {
            copyValue.append(tag)
        }
        tagFilter.accept(copyValue)
        setCache(gameTags: copyValue)
    }
    
    private func setCache(isRecommend: Bool? = nil, isNew: Bool? = nil, gameTags:[ProductDTO.GameTag]? = nil){
        let filters: [GameFilter] = memoryCache.getGameTag(.numberGameTag) ?? []
        
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
        
        var gameFilters: [GameFilter]
        if gameTags == nil {
            gameFilters = filters.filter({ $0 is GameFilter.Tag})
        } else {
            gameFilters = gameTags!.map({ GameFilter.Tag.init(tag: GameTag.init(type: $0.id, name: $0.name)) })
        }
        
        if(recommend) { gameFilters.append(GameFilter.Promote.init()) }
        if(new) { gameFilters.append(GameFilter.New.init()) }
        
        memoryCache.setGameTag(.numberGameTag, gameFilters)
    }
    
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    var gameSorting = BehaviorRelay<GameSorting>(value: .popular)
    
    init(numberGameUseCase: NumberGameUseCase, memoryCache: MemoryCacheImpl, numberGameService: INumberGameAppService) {
        self.numberGameUseCase = numberGameUseCase
        self.memoryCache = memoryCache
        self.numberGameService = numberGameService
        super.init()
        if let tags: [GameFilter] = memoryCache.getGameTag(.numberGameTag) {
            tagFilter.accept(tags.filter({$0 is GameFilter.Tag}).map{ $0 as! GameFilter.Tag }.map({
                ProductDTO.GameTag.init(id: $0.tag.type, name: $0.tag.name)
            }))
            if tags.contains(GameFilter.New.init()) {
                newFilter.accept(true)
            }
            if tags.contains(GameFilter.Promote.init()) {
                recommendFilter.accept(true)
            }
        }
    }
    
    private func updateGameSorting() {
        if recommendFilter.value {
            updateGameSorting(sorting: .popular)
        } else if newFilter.value {
            updateGameSorting(sorting: .releaseddate)
        } else {
            updateGameSorting(sorting: .popular)
        }
    }
    
    func updateGameSorting(sorting: GameSorting) {
        gameSorting.accept(sorting)
    }
    
    private func addFavorite(_ game: WebGameWithDuplicatable) -> Completable {
        return numberGameUseCase.addFavorite(game: game)
    }
    
    private func removeFavorite(_ game: WebGameWithDuplicatable) -> Completable {
        return numberGameUseCase.removeFavorite(game: game)
    }
    
    private func getTags() -> Observable<[GameTag]> {
        return numberGameUseCase.getGameTags().asObservable().share(replay: 1)
    }
    
}

extension NumberGameViewModel: ProductViewModel {
    func getFavorites() {
        favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
        numberGameUseCase.getFavorites().subscribe(onNext: { [weak self] (games) in
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
        ProductType.numbergame
    }
    
    func favoriteProducts() -> Observable<[WebGameWithDuplicatable]> {
        return favorites.asObservable()
    }
    
    func toggleFavorite(game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
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
    
    func getGameProduct() -> String {
        return "numbergame"
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return numberGameUseCase.createGame(gameId: gameId)
    }
    
    func clearSearchResult() {
        triggerSearch("")
    }
    
    func searchSuggestion() -> Single<[String]> {
        return self.numberGameUseCase.getSuggestKeywords()
    }
    
    func triggerSearch(_ text: String?) {
        guard let txt = text else { return }
        self.searchKey.accept(SearchKeyword(keyword: txt))
    }
    
    func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
        return self.searchKey.flatMapLatest { [unowned self] (keyword) -> Observable<Event<[WebGameWithDuplicatable]>> in
            return self.numberGameUseCase.searchGames(keyword: keyword).materialize()
        }
    }
}
