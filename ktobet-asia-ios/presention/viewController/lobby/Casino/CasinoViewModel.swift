import Foundation
import RxSwift
import RxCocoa
import SharedBu

class CasinoViewModel: KTOViewModel {
    private var casinoRecordUseCase : CasinoRecordUseCase!
    private var casinoUseCase: CasinoUseCase!
    private var memoryCache: MemoryCacheImpl!
    // MARK: GameTags
    private var gameFilter = BehaviorRelay<[CasinoTag]>(value: [])
    private var gameTags: [CasinoTag] = []
    lazy var casinoGameTagStates: Observable<[CasinoTag]> = Observable.combineLatest(gameFilter.asObservable(), getCasinoBetTypeTags()) { [weak self] (filters, tags) in
        var gameTags: [CasinoTag] = tags.map({ CasinoTag($0)})
        filters.forEach { (filter) in
            gameTags.filter { $0.tagId == filter.tagId }.first?.isSelected = filter.isSelected
        }
        self?.gameTags = gameTags
        return gameTags
    }
    // MARK: CasinoGames
    lazy var searchedCasinoByTag = gameFilter.flatMap { [unowned self] (filters) -> Observable<[CasinoGame]> in
        var tags: [CasinoGameTag] = []
        filters.forEach { (filter) in
            if filter.isSelected {
                tags.append(filter.getCasinoGameTag())
            }
        }
        return self.searchedCasinoByTag(tags: tags)
    }
    // MARK: Favorites
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    // MARK: Search
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    
    lazy var betSummary = casinoRecordUseCase.getBetSummary()
    var betTime: [String] = []
    var pagination: Pagination<BetRecord>!
    var periodOfRecord: PeriodOfRecord!
    var section: Int = 0
    private let refreshTrigger = PublishSubject<Void>()
    
    private var disposeBag = DisposeBag()
    
    init(casinoRecordUseCase: CasinoRecordUseCase, casinoUseCase: CasinoUseCase, memoryCache: MemoryCacheImpl) {
        super.init()
        self.casinoRecordUseCase = casinoRecordUseCase
        self.casinoUseCase = casinoUseCase
        self.memoryCache = memoryCache
        if let tags: [CasinoTag] = memoryCache.getGameTag(.casinoGameTag) {
            gameFilter.accept(tags)
        }
        
        pagination = Pagination<BetRecord>(pageIndex: 0, offset: 20, callBack: {(page) -> Observable<[BetRecord]> in
            self.getBetRecords(offset: page)
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[BetRecord]> in
                    Observable.empty()
                })
        })
    }
    
    private func searchedCasinoByTag(tags: [CasinoGameTag]) -> Observable<[CasinoGame]> {
        return casinoUseCase.searchGamesByTag(tags: tags).compose(applyObservableErrorHandle()).catchError { error in
            return Observable.error(error)
        }.retry()
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
        } else if let oldTag = copyValue.filter({ $0.tagId == Int32(gameTagId) }).first {
            oldTag.isSelected.toggle()
        } else if let filter = gameTags.filter({ $0.tagId == Int32(gameTagId)}).first {
            filter.isSelected.toggle()
            copyValue.append(filter)
        }
        memoryCache.setGameTag(.casinoGameTag, copyValue)
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
        return casinoRecordUseCase.getBetSummaryByDate(localDate: localDate).do(onSuccess: { (periodOfRecords) in
            self.periodOfRecord = periodOfRecords.first
        })
    }
    
    func getBetRecords(offset: Int) -> Observable<[BetRecord]> {
        return casinoRecordUseCase.getBetRecords(periodOfRecord: self.periodOfRecord, offset: offset).asObservable()
    }
    
    func getBetRecords(periodOfRecords: [PeriodOfRecord], offset: Int) -> Observable<[PeriodOfRecord: [BetRecord]]> {
        var obs: [Observable<[PeriodOfRecord: [BetRecord]]>] = []
        for p in periodOfRecords {
            let o = casinoRecordUseCase.getBetRecords(periodOfRecord: p, offset: offset).map { (betRecords) -> [PeriodOfRecord: [BetRecord]] in
                return [p: betRecords]
            }.asObservable()
            
            obs.append(o)
        }
        
        return Observable.merge(obs)
    }
    
    func getWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
        return casinoRecordUseCase.getCasinoWagerDetail(wagerId: wagerId)
    }
    
    private func addFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
        return casinoUseCase.addFavorite(game: casinoGame)
    }
    
    private func removeFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
        return casinoUseCase.removeFavorite(game: casinoGame)
    }
    
    // MARK: Lobby
    func getLobbyGames(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
        refreshTrigger.flatMapLatest { [unowned self] in self.casinoUseCase.searchGamesByLobby(lobby: lobby) }
    }
    
    func refreshLobbyGames() {
        refreshTrigger.onNext(())
    }
}

class CasinoTag: NSObject, BaseGameTag {
    private let bean: CasinoGameTag
    var isSelected: Bool = false
    var tagId: Int32 {
        return bean.id
    }
    var name: String {
        return bean.name
    }
    init(_ model: CasinoGameTag, isSeleced: Bool = false) {
        self.bean = model
        self.isSelected = isSeleced
    }
    
    func getCasinoGameTag() -> CasinoGameTag {
        return bean
    }
}

extension CasinoViewModel: ProductViewModel {
    func getFavorites() {
        favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
        casinoUseCase.getFavorites().subscribe(onNext: { [weak self] (games) in
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
        ProductType.casino
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
    
    func clearSearchResult() {
        triggerSearch("")
    }
    
    func searchSuggestion() -> Single<[String]> {
        return self.casinoUseCase.getSuggestKeywords()
    }
    
    func triggerSearch(_ keyword: String?) {
        guard let keyword = keyword else { return }
        self.searchKey.accept(SearchKeyword(keyword: keyword))
    }
    
    func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
        return self.searchKey.flatMapLatest { [unowned self] (keyword) -> Observable<Event<[WebGameWithDuplicatable]>> in
            return self.casinoUseCase.searchGames(keyword: keyword).materialize()
        }
    }
    
    func getGameProduct() -> String { "casino" }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return casinoUseCase.createGame(gameId: gameId)
    }

}
