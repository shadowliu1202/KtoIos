import Foundation
import RxSwift
import RxCocoa
import SharedBu

class NumberGameViewModel {
    lazy var popularGames = numberGameUseCase.getPopularGames()
    lazy var allGames = Observable.combineLatest(gameSorting, filterSets).flatMapLatest { (gameSorting, gameFilters) ->  Observable<[NumberGame]> in
        return self.numberGameUseCase.getGames(order: gameSorting, tags: gameFilters)
    }
    
    var favorites = BehaviorSubject<[NumberGame]>(value: [])
    
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
        tags.filter{ $0.isSelected && $0.id >= 0 }.forEach{ gameFilters.insert(GameFilter.Tag.init(tag: $0.getGameTag())) }
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
            gameTags.filter { $0.id == filter.id }.first?.isSelected = filter.isSelected
        }
        self?.gameTags = gameTags
        return gameTags
    }
    
    init(numberGameUseCase: NumberGameUseCase, memoryCache: MemoryCacheImpl) {
        self.numberGameUseCase = numberGameUseCase
        self.memoryCache = memoryCache
        if let tags = memoryCache.getNumberGameTag() {
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
        } else if let oldTag = copyValue.filter({ $0.id == Int32(gameTagId) }).first {
            oldTag.isSelected.toggle()
        } else if let filter = gameTags.filter({ $0.id == Int32(gameTagId)}).first {
            filter.isSelected.toggle()
            copyValue.append(filter)
        }

        memoryCache.setNumberGameTag(copyValue)
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
    
    private func addFavorite(_ game: NumberGame) -> Completable {
        return numberGameUseCase.addFavorite(game: game).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: game) {
                    copyValue[i] = NumberGame.duplicateGame(game, isFavorite: true)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
    private func removeFavorite(_ game: NumberGame) -> Completable {
        return numberGameUseCase.removeFavorite(game: game).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: game) {
                    copyValue[i] = NumberGame.duplicateGame(game, isFavorite: false)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
    private func getTags() -> Observable<[GameTag]> {
        return numberGameUseCase.getGameTags().asObservable().share(replay: 1)
    }
    
}

extension NumberGameViewModel: ProductViewModel {
    func getFavorites() {
        favorites = BehaviorSubject<[NumberGame]>(value: [])
        numberGameUseCase.getFavorites().subscribe(onSuccess: { [weak self] (games) in
            if games.count > 0 {
                self?.favorites.onNext(games)
            } else {
                self?.favorites.onError(KTOError.EmptyData)
            }
        }, onError: { [weak self] (e) in
            self?.favorites.onError(e)
        }).disposed(by: disposeBag)
    }
    
    func favoriteProducts() -> Observable<[WebGameWithProperties]> {
        return favorites.map({ $0.map({$0 as WebGameWithProperties})}).asObservable()
    }
    
    func toggleFavorite(game: WebGameWithProperties, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
        guard game is NumberGame else { return }
        let numGame = game as! NumberGame
        if numGame.isFavorite {
            removeFavorite(numGame).subscribe(onCompleted: {
                onCompleted(.remove)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        } else {
            addFavorite(numGame).subscribe(onCompleted: {
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
        return self.numberGameUseCase.getSuggestionKeywords()
    }
    
    func triggerSearch(_ text: String?) {
        guard let txt = text else { return }
        self.searchKey.accept(SearchKeyword(keyword: txt))
    }
    
    func searchResult() -> Observable<Event<[WebGameWithProperties]>> {
        return self.searchKey.flatMapLatest { [unowned self] (keyword) -> Observable<Event<[WebGameWithProperties]>> in
            return self.numberGameUseCase.searchGames(keyword: keyword).map({ $0.map({$0 as WebGameWithProperties})}).materialize()
        }
    }
}

class NumberGameTag: NSObject {
    private let bean: GameTag
    var isSelected: Bool = false
    var id: Int32 {
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
