import Foundation
import RxSwift
import RxCocoa
import share_bu

class SlotViewModel {
    lazy var popularGames = slotUseCase.getPopularSlots()
    lazy var recentGames = slotUseCase.getRecentlyPlaySlots()
    lazy var newGames = slotUseCase.getNewSlots()
    lazy var jackpotGames = slotUseCase.getJackpotSlots()
    var favorites = BehaviorSubject<[SlotGame]>(value: [])
    
    private var slotUseCase: SlotUseCase!
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    private var disposeBag = DisposeBag()
    lazy var gameCountWithSearchFilters = Observable<(Int, [SlotGameFilter])>.combineLatest(gameCount, gameCountFilters) { ($0, $1) }
    lazy var gameCountFilters = BehaviorSubject<[SlotGameFilter]>(value: [])
    lazy var gameCount = gameCountFilters.flatMapLatest { (filters) -> Observable<Int> in
        let featureTags: Set<SlotGameFilter.SlotGameFeature> = Set(filters.filter{ $0 is SlotGameFilter.SlotGameFeature }.map{ $0 as! SlotGameFilter.SlotGameFeature })
        let themeTags: Set<SlotGameFilter.SlotGameTheme> = Set(filters.filter{ $0 is SlotGameFilter.SlotGameTheme }.map{ $0 as! SlotGameFilter.SlotGameTheme })
        let payLineWayTags: Set<SlotGameFilter.SlotPayLineWay> = Set(filters.filter{ $0 is SlotGameFilter.SlotPayLineWay }.map{ $0 as! SlotGameFilter.SlotPayLineWay })
        return self.slotUseCase.gameCount(isJackpot: false,
                                          isNew: false,
                                          featureTags: featureTags,
                                          themeTags: themeTags,
                                          payLineWayTags: payLineWayTags)
    }
    
    init(slotUseCase: SlotUseCase) {
        self.slotUseCase = slotUseCase
    }
    
    func gatAllGame(sorting: GameSorting, filters: [SlotGameFilter] = []) -> Observable<[SlotGame]> {
        let featureTags: Set<SlotGameFilter.SlotGameFeature> = Set(filters.filter{ $0 is SlotGameFilter.SlotGameFeature }.map{ $0 as! SlotGameFilter.SlotGameFeature })
        let themeTags: Set<SlotGameFilter.SlotGameTheme> = Set(filters.filter{ $0 is SlotGameFilter.SlotGameTheme }.map{ $0 as! SlotGameFilter.SlotGameTheme })
        let payLineWayTags: Set<SlotGameFilter.SlotPayLineWay> = Set(filters.filter{ $0 is SlotGameFilter.SlotPayLineWay }.map{ $0 as! SlotGameFilter.SlotPayLineWay })

        return self.slotUseCase.searchSlot(sortBy: sorting, isJackpot: false, isNew: false, featureTags: featureTags, themeTags: themeTags, payLineWayTags: payLineWayTags)
    }
    
    private func addFavorite(_ slotGame: SlotGame) -> Completable {
        return slotUseCase.addFavorite(slotGame: slotGame).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: slotGame) {
                    copyValue[i] = SlotGame.duplicateGame(slotGame, isFavorite: true)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
    private func removeFavorite(_ slotGame: SlotGame) -> Completable {
        return slotUseCase.removeFavorite(slotGame: slotGame).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: slotGame) {
                    copyValue[i] = SlotGame.duplicateGame(slotGame, isFavorite: false)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
}

extension SlotViewModel: ProductViewModel {
    func getFavorites() {
        favorites = BehaviorSubject<[SlotGame]>(value: [])
        slotUseCase.favoriteSlots().subscribe(onSuccess: { [weak self] (games) in
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
        guard game is SlotGame else { return }
        let slot = game as! SlotGame
        if slot.isFavorite {
            removeFavorite(slot).subscribe(onCompleted: {
                onCompleted(.remove)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        } else {
            addFavorite(slot).subscribe(onCompleted: {
                onCompleted(.add)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        }
    }
    
    func clearSearchResult() {
        triggerSearch("")
    }
    
    func searchSuggestion() -> Single<[String]> {
        return self.slotUseCase.getSuggestionKeywords()
    }
    
    func triggerSearch(_ keyword: String?) {
        guard let keyword = keyword else { return }
        self.searchKey.accept(SearchKeyword(keyword: keyword))
    }
    
    func searchResult() -> Observable<Event<[WebGameWithProperties]>> {
        return self.searchKey.flatMapLatest { [unowned self] (keyword) -> Observable<Event<[WebGameWithProperties]>> in
            return self.slotUseCase.searchSlots(keyword: keyword).map({ $0.map({$0 as WebGameWithProperties})}).materialize()
        }
    }
    
    func getGameProduct() -> String{ "slot" }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return slotUseCase.createGame(gameId: gameId)
    }
}
