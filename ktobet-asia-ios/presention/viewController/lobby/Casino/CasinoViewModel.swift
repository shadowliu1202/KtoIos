import Foundation
import RxSwift
import RxCocoa
import SharedBu

class CasinoViewModel: CollectErrorViewModel, ProductViewModel {
    @Injected private var loading: Loading
  
    private let casinoRecordUseCase : CasinoRecordUseCase
    private let casinoUseCase: CasinoUseCase
    private let memoryCache: MemoryCacheImpl
    private let casinoAppService: ICasinoAppService
    
    private let refreshTrigger = PublishSubject<Void>()
    
    private let webGameResultSubject = PublishSubject<WebGameResult>()
    
    private let disposeBag = DisposeBag()
    
    private lazy var gameTags = RxSwift.Single<CasinoDTO.GameTags>.from(casinoAppService.getTags()).asObservable()
    
    private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
    
    private var tagFilter = BehaviorRelay<[ProductDTO.GameTag]>(value: [])
    
    lazy var tagStates = Observable
        .combineLatest(tagFilter, gameTags)
        .map { (filter, gameTags) in
            return gameTags.gameTags.map { ($0, filter.contains($0)) }
        }
        .compose(applyObservableErrorHandle())
    
    lazy var searchedCasinoByTag = tagFilter
        .flatMap { [unowned self] (filters) -> Observable<[CasinoGame]> in
            return self.searchedCasinoByTag(tags: filters)
        }
    
    lazy var betSummary = casinoRecordUseCase.getBetSummary()
    
    var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
    
    var betTime: [SharedBu.LocalDateTime] = []
    
    var pagination: Pagination<BetRecord>!
    
    var periodOfRecord: PeriodOfRecord!
    
    var section: Int = 0
    
    var webGameResultDriver: Driver<WebGameResult> {
        webGameResultSubject.asDriverLogError()
    }
    
    var loadingTracker: ActivityIndicator { loading.tracker }
    
    init(
        casinoRecordUseCase: CasinoRecordUseCase,
        casinoUseCase: CasinoUseCase,
        memoryCache: MemoryCacheImpl,
        casinoAppService: ICasinoAppService
    ) {
        self.casinoRecordUseCase = casinoRecordUseCase
        self.casinoUseCase = casinoUseCase
        self.memoryCache = memoryCache
        self.casinoAppService = casinoAppService
        
        super.init()
        
        if let tags: [GameFilter] = memoryCache.getGameTag(.casinoGameTag) {
            tagFilter.accept(tags.filter({$0 is GameFilter.Tag}).map{ $0 as! GameFilter.Tag }.map({
                ProductDTO.GameTag.init(id: $0.tag.type, name: $0.tag.name)
            }))
        }
        
        pagination = Pagination<BetRecord>(pageIndex: 0, offset: 20, observable: { [unowned self] (page) -> Observable<[BetRecord]> in
            self.getBetRecords(offset: page)
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catch({ error -> Observable<[BetRecord]> in
                    Observable.empty()
                })
        })
    }
    
    func selectAll() {
        tagFilter.accept([])
        setCache(gameTags: [])
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
    
    private func setCache(gameTags: [ProductDTO.GameTag]) {
        let gameFilters: [GameFilter] = gameTags.map({ GameFilter.Tag.init(tag: GameTag.init(type: $0.id, name: $0.name)) })
        memoryCache.setGameTag(.casinoGameTag, gameFilters)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - Game

extension CasinoViewModel {
    
    func getGameProduct() -> String { "casino" }
    
    func getGameProductType() -> ProductType {
        ProductType.casino
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

    func getLobbyGames(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
        refreshTrigger.flatMapLatest { [unowned self] in self.casinoUseCase.searchGamesByLobby(lobby: lobby) }
    }
    
    func refreshLobbyGames() {
        refreshTrigger.onNext(())
    }
    
    private func getCasinoBetTypeTags() -> Observable<[CasinoGameTag]> {
        return casinoUseCase.getCasinoBetTypeTags().asObservable().share(replay: 1)
    }
    
    func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
        casinoUseCase.checkBonusAndCreateGame(game)
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

// MARK: - Favorite

extension CasinoViewModel {
    
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
    
    private func addFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
        return casinoUseCase.addFavorite(game: casinoGame)
    }
    
    private func removeFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
        return casinoUseCase.removeFavorite(game: casinoGame)
    }
}

// MARK: - Search

extension CasinoViewModel {
    
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
    
    private func searchedCasinoByTag(tags: [ProductDTO.GameTag]) -> Observable<[CasinoGame]> {
        casinoUseCase
            .searchGamesByTag(tags: tags)
            .compose(applyObservableErrorHandle())
            .catch { error in
                return Observable.error(error)
            }
            .retry(3)
    }
}

// MARK: - Record

extension CasinoViewModel {
    
    func getUnsettledBetSummary() -> Observable<[UnsettledBetSummary]> {
        return casinoRecordUseCase.getUnsettledSummary()
            .do(onSuccess: { [unowned self] in
                $0.forEach{ self.betTime.append($0.betTime) }
            })
            .asObservable()
    }
    
    func getUnsettledRecords(betTime: SharedBu.LocalDateTime) -> Single<[SharedBu.LocalDateTime: [UnsettledBetRecord]]> {
        return casinoRecordUseCase.getUnsettledRecords(date: betTime).map{ [betTime: $0] }
    }
    
    func getUnsettledRecords() -> Observable<[SharedBu.LocalDateTime: [UnsettledBetRecord]]> {
        let allObservables = betTime.map{ getUnsettledRecords(betTime: $0).asObservable() }
        return Observable.merge(allObservables)
    }
    
    func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]> {
        return casinoRecordUseCase.getBetSummaryByDate(localDate: localDate)
            .do(onSuccess: { [unowned self] (periodOfRecords) in
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
}
