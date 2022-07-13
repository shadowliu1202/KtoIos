import Foundation
import RxSwift
import RxCocoa
import SharedBu


class ArcadeViewModel: KTOViewModel {
    private var arcadeUseCase: ArcadeUseCase!
    private var memoryCache: MemoryCacheImpl!
    
    var gameFilter = BehaviorRelay<[ArcadeGameTag]>(value: [])
    lazy var gameSource = gameFilter.flatMapLatest({
        return self.arcadeUseCase.getGames(tags: $0.filter({$0.isSelected}).flatMap{ $0.getGameFilter() }).compose(self.applyObservableErrorHandle()).catchError { error in
            return Observable.error(error)
        }.retry()
    })
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    private var disposeBag = DisposeBag()
    
    init(arcadeUseCase: ArcadeUseCase, memoryCache: MemoryCacheImpl) {
        super.init()
        self.arcadeUseCase = arcadeUseCase
        self.memoryCache = memoryCache
        setupGameFilter(memoryCache.getGameTag(.arcadeGameTag))
    }
    
    private func setupGameFilter(_ tags: [ArcadeGameTag]?) {
        if let tags = tags {
            gameFilter.accept(tags)
        } else {
            let tagAll: ArcadeGameTag = ArcadeGameTag(TagAllID, name: Localize.string("common_all"), isSelected: true)
            let tagRecommand: ArcadeGameTag = ArcadeGameTag(TagRecommandID, name: Localize.string("common_recommend"))
            let tagNew: ArcadeGameTag = ArcadeGameTag(TagNewID, name: Localize.string("common_new"))
            gameFilter.accept([tagAll, tagRecommand, tagNew])
        }
    }
    
    func toggleFilter(gameTagId: Int) {
        let copyValue = gameFilter.value
        copyValue.forEach({ (element) in
            if gameTagId == TagAllID {
                if element.tagId == gameTagId {
                    element.isSelected = true
                } else {
                    element.isSelected = false
                }
            } else {
                if element.tagId == TagAllID {
                    element.isSelected = false
                } else if element.tagId == gameTagId {
                    element.isSelected.toggle()
                }
            }
        })
        if gameFilter.value.allSatisfy({ $0.isSelected == false }), let tagAll = copyValue.filter({ $0.tagId == TagAllID }).first {
            tagAll.isSelected = true
        }
        memoryCache.setGameTag(.arcadeGameTag, gameFilter.value)
        gameFilter.accept(copyValue)
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

class ArcadeGameTag: NSObject, BaseGameTag {
    private(set) var tagId: Int32
    var isSelected: Bool = false
    var name: String
    
    init(_ tagId: Int32, name: String, isSelected: Bool = false) {
        self.tagId = tagId
        self.isSelected = isSelected
        self.name = name
    }
    
    func getGameFilter() -> [GameFilter] {
        switch tagId {
        case TagAllID:
            return []
        case TagRecommandID:
            return [.Promote()]
        case TagNewID:
            return [.New()]
        default:
            return []
        }
    }
}
