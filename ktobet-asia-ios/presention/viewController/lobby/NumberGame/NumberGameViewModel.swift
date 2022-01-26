import Foundation
import RxSwift
import RxCocoa
import SharedBu

class NumberGameViewModel: KTOViewModel {
    lazy var popularGames = numberGameUseCase.getPopularGames()
    lazy var allGames = Observable.combineLatest(gameSorting, filterSets).flatMapLatest { (gameSorting, gameFilters) ->  Observable<[NumberGame]> in
        return self.numberGameUseCase.getGames(order: gameSorting, tags: gameFilters).compose(self.applyObservableErrorHandle()).catchError { error in
            return Observable.error(error)
        }.retry()
    }
    
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    
    private var numberGameUseCase: NumberGameUseCase!
    private var memoryCache: MemoryCacheImpl!
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    
    var tagFilter = BehaviorRelay<[NumberGameTag]>(value: [])
    var recommendFilter = BehaviorRelay<Bool>(value: false)
    var newFilter = BehaviorRelay<Bool>(value: false)
    var gameSorting = BehaviorRelay<GameSorting>(value: .popular)
    
    private var disposeBag = DisposeBag()
    private lazy var filterSets: Observable<Set<GameFilter>> = Observable.combineLatest(tagFilter, recommendFilter, newFilter) { (tags, recommand, new) -> Set<GameFilter> in
        var gameFilters: Set<GameFilter> = []
        tags.filter{ $0.isSelected && $0.tagId >= 0 }.forEach{ gameFilters.insert(GameFilter.Tag.init(tag: $0.getGameTag())) }
        if recommand { gameFilters.insert(GameFilter.Promote.init()) }
        if new { gameFilters.insert(GameFilter.New.init()) }
        return gameFilters
    }
    
    var gameTags: [NumberGameTag] = []
    lazy var gameTagStates: Observable<[NumberGameTag]> = Observable.combineLatest(tagFilter.asObservable(), getTags()) { [weak self] (filters, tags) in
        var gameTags: [NumberGameTag] = []
        gameTags.append(NumberGameTag(GameTag.init(type: -2, name: Localize.string("common_recommend"))))
        gameTags.append(NumberGameTag(GameTag.init(type: -3, name: Localize.string("common_new"))))
        gameTags.append(contentsOf: tags.map({ NumberGameTag($0)}))
        filters.forEach { (filter) in
            gameTags.filter { $0.tagId == filter.tagId }.first?.isSelected = filter.isSelected
        }
        self?.gameTags = gameTags
        return gameTags
    }
    
    init(numberGameUseCase: NumberGameUseCase, memoryCache: MemoryCacheImpl) {
        super.init()
        self.numberGameUseCase = numberGameUseCase
        self.memoryCache = memoryCache
        if let tags: [NumberGameTag] = memoryCache.getGameTag(.numberGameTag) {
            tagFilter.accept(tags)
        }
    }
    
    func setRecommendFilter(isRecommand: Bool) {
        recommendFilter.accept(isRecommand)
        updateGameSorting()
    }
    
    func setNewFilter(isNew: Bool) {
        newFilter.accept(isNew)
        updateGameSorting()
    }
    
    func toggleFilter(gameTagId: Int) {
        var copyValue = tagFilter.value
        if gameTagId == TagAllID {
            copyValue.removeAll()
        } else if let oldTag = copyValue.filter({ $0.tagId == Int32(gameTagId) }).first {
            oldTag.isSelected.toggle()
        } else if let filter = gameTags.filter({ $0.tagId == Int32(gameTagId)}).first {
            filter.isSelected.toggle()
            copyValue.append(filter)
        }

        memoryCache.setGameTag(.numberGameTag, copyValue)
        tagFilter.accept(copyValue)
    }
    
    func clearFilter() {
        tagFilter.accept([])
        recommendFilter.accept(false)
        newFilter.accept(false)
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

class NumberGameTag: NSObject, BaseGameTag {
    private let bean: GameTag
    var isSelected: Bool = false
    var tagId: Int32 {
        return bean.type
    }
    var name: String {
        return bean.name
    }
    
    init(_ model: GameTag, isSelected: Bool = false) {
        self.bean = model
        self.isSelected = isSelected
    }
    
    func getGameTag() -> GameTag {
        return bean
    }
}
