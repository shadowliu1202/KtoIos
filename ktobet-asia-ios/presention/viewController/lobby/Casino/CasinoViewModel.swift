import Foundation
import RxSwift
import RxCocoa
import share_bu

enum FavoriteAction {
    case add
    case remove
}

class CasinoViewModel {
    private var casinoRecordUseCase : CasinoRecordUseCase!
    private var casinoUseCase: CasinoUseCase!
    private var memoryCache: MemoryCacheImpl!
    // MARK: GameTags
    private var gameFilter = BehaviorRelay<[CasinoTag]>(value: [])
    private var gameTags: [CasinoTag] = []
    lazy var casinoGameTagStates: Observable<[CasinoTag]> = Observable.combineLatest(gameFilter.asObservable(), getCasinoBetTypeTags()) { [weak self] (filters, tags) in
        var gameTags: [CasinoTag] = tags.map({ CasinoTag($0)})
        filters.forEach { (filter) in
            gameTags.filter { $0.id == filter.id }.first?.isSeleced = filter.isSeleced
        }
        self?.gameTags = gameTags
        return gameTags
    }
    // MARK: CasinoGames
    lazy var searchedCasinoByTag = gameFilter.flatMap { [unowned self] (filters) -> Observable<[CasinoGame]> in
        var tags: [CasinoGameTag] = []
        filters.forEach { (filter) in
            if filter.isSeleced {
                tags.append(filter.getCasinoGameTag())
            }
        }
        return self.searchedCasinoByTag(tags: tags)
    }
    // MARK: Favorites
    var favorites = BehaviorSubject<[CasinoGame]>(value: [])
    // MARK: Search
    lazy var searchSuggestion: Single<[String]> = { return self.casinoUseCase.getSuggestKeywords() }()
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    lazy var searchResult = searchKey.flatMap { [unowned self] (keyword) -> Observable<[CasinoGame]> in
        return self.casinoUseCase.searchGamesByKeyword(keyword: keyword)
    }
    
    lazy var betSummary = casinoRecordUseCase.getBetSummary()
    var betTime: [String] = []
    
    private var disposeBag = DisposeBag()
    
    init(casinoRecordUseCase: CasinoRecordUseCase, casinoUseCase: CasinoUseCase, memoryCache: MemoryCacheImpl) {
        self.casinoRecordUseCase = casinoRecordUseCase
        self.casinoUseCase = casinoUseCase
        self.memoryCache = memoryCache
        if let tags = memoryCache.getCasinoGameTag() {
            gameFilter.accept(tags)
        }
    }
    
    private func searchedCasinoByTag(tags: [CasinoGameTag]) -> Observable<[CasinoGame]> {
        return casinoUseCase.searchGamesByTag(tags: tags)
    }
    
    private func getCasinoBetTypeTags() -> Observable<[CasinoGameTag]> {
        return casinoUseCase.getCasinoBetTypeTags().asObservable().share(replay: 1)
    }
    
    func lobby() -> Single<[CasinoLobby]> {
        return casinoUseCase.getLobbies().flatMap { (lobbies) -> Single<[CasinoLobby]> in
            if lobbies.count > 0 {
                return Single.just(lobbies.filter({$0.lobby != .none}))
            } else {
                return Single.error(KTOError.EmptyData)
            }
        }
    }
    
    func toggleFilter(gameTagId: Int) {
        var copyValue = gameFilter.value
        if gameTagId == TagAllID {
            copyValue.removeAll()
        } else if let oldTag = copyValue.filter({ $0.id == Int32(gameTagId) }).first {
            oldTag.isSeleced.toggle()
        } else if let filter = gameTags.filter({ $0.id == Int32(gameTagId)}).first {
            filter.isSeleced.toggle()
            copyValue.append(filter)
        }
        memoryCache.setCasinoGameTag(copyValue)
        gameFilter.accept(copyValue)
    }
    
    func getUnsettledBetSummary() -> Observable<[UnsettledBetSummary]> {
        return casinoRecordUseCase.getUnsettledSummary().do(onSuccess: { $0.forEach{ self.betTime.append("\($0.betTime.date)") } }).asObservable()
    }
    
    func getUnsettledRecords(betTime: String) -> Single<[String: [UnsettledBetRecord]]> {
        return casinoRecordUseCase.getUnsettledRecords(date: betTime).map{ [betTime: $0] }
    }
    
    func getUnsettledRecords() -> Observable<[String: [UnsettledBetRecord]]> {
        let allObservables = betTime.map{ getUnsettledRecords(betTime: $0).asObservable() }
        return Observable.merge(allObservables)
    }
    
    func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]> {
        return casinoRecordUseCase.getBetSummaryByDate(localDate: localDate)
    }
    
    func getBetRecords(periodOfRecords: [PeriodOfRecord]) -> Observable<[PeriodOfRecord: [BetRecord]]> {
        var obs: [Observable<[PeriodOfRecord: [BetRecord]]>] = []
        for p in periodOfRecords {
            let o = casinoRecordUseCase.getBetRecords(periodOfRecord: p).map { (betRecords) -> [PeriodOfRecord: [BetRecord]] in
                return [p: betRecords]
            }.asObservable()
            
            obs.append(o)
        }
        
        return Observable.merge(obs)
    }
    
    func getWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
        return casinoRecordUseCase.getCasinoWagerDetail(wagerId: wagerId)
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return casinoUseCase.createGame(gameId: gameId)
    }
    
    func toggleFavorite(casinoGame: CasinoGame, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
        if casinoGame.isFavorite {
            removeFavorite(casinoGame).subscribe(onCompleted: {
                onCompleted(.remove)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        } else {
            addFavorite(casinoGame).subscribe(onCompleted: {
                onCompleted(.add)
            }, onError: { (error) in
                onError(error)
            }).disposed(by: disposeBag)
        }
    }
    
    private func addFavorite(_ casinoGame: CasinoGame) -> Completable {
        return casinoUseCase.addFavorite(casinoGame: casinoGame).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: casinoGame) {
                    copyValue[i] = CasinoGame(gameId: casinoGame.gameId, gameName: casinoGame.gameName, isFavorite: true, gameStatus: casinoGame.gameStatus, thumbnail: casinoGame.thumbnail, releaseDate: casinoGame.releaseDate)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
    private func removeFavorite(_ casinoGame: CasinoGame) -> Completable {
        return casinoUseCase.removeFavorite(casinoGame: casinoGame).do(onCompleted: { [weak self] in
            if var copyValue = try? self?.favorites.value() {
                if let i = copyValue.firstIndex(of: casinoGame) {
                    copyValue[i] = CasinoGame(gameId: casinoGame.gameId, gameName: casinoGame.gameName, isFavorite: false, gameStatus: casinoGame.gameStatus, thumbnail: casinoGame.thumbnail, releaseDate: casinoGame.releaseDate)
                }
                self?.favorites.onNext(copyValue)
            }
        })
    }
    
    // MARK: Favorites
    func getFavorites() {
        favorites = BehaviorSubject<[CasinoGame]>(value: [])
        casinoUseCase.getFavorites().subscribe(onSuccess: { [weak self] (games) in
            if games.count > 0 {
                self?.favorites.onNext(games)
            } else {
                self?.favorites.onError(KTOError.EmptyData)
            }
        }, onError: { [weak self] (e) in
            self?.favorites.onError(e)
        }).disposed(by: disposeBag)
    }
    // MARK: Search
    func clearSearchResult() {
        triggerSearch("")
    }
    func triggerSearch(_ keyword: String?) {
        guard let keyword = keyword else { return }
        self.searchKey.accept(SearchKeyword(keyword: keyword))
    }
    // MARK: Lobby
    func getLobbyGames(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
        return casinoUseCase.searchGamesByLobby(lobby: lobby)
    }
}

class CasinoTag: NSObject {
    private let bean: CasinoGameTag
    var isSeleced: Bool = false
    var id: Int32 {
        return bean.id
    }
    var name: String {
        return bean.name
    }
    init(_ model: CasinoGameTag, isSeleced: Bool = false) {
        self.bean = model
        self.isSeleced = isSeleced
    }
    
    func getCasinoGameTag() -> CasinoGameTag {
        return bean
    }
}
