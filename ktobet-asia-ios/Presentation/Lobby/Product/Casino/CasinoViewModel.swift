import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CasinoViewModel: CollectErrorViewModel, ProductViewModel {
  @Injected private var loading: Loading

  private let casinoRecordUseCase: CasinoRecordUseCase
  private let casinoUseCase: CasinoUseCase
  private let memoryCache: MemoryCacheImpl
  private let casinoGameAppService: ICasinoGameAppService
  private let casinoMyBetAppService: ICasinoMyBetAppService

  private let refreshTrigger = PublishSubject<Void>()

  private let webGameResultSubject = PublishSubject<WebGameResult>()

  private let disposeBag = DisposeBag()

  private lazy var gameTags = RxSwift.Single<CasinoDTO.GameTags>.from(casinoGameAppService.getTags()).asObservable()

  private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))

  private var tagFilter = BehaviorRelay<[ProductDTO.GameTag]>(value: [])

  lazy var tagStates = Observable
    .combineLatest(tagFilter, gameTags)
    .map { filter, gameTags in
      gameTags.gameTags.map { ($0, filter.contains($0)) }
    }
    .compose(applyObservableErrorHandle())

  lazy var searchedCasinoByTag = tagFilter
    .flatMap { [unowned self] filters in
      self.searchedCasinoByTag(tags: filters)
    }

  lazy var betSummary = casinoRecordUseCase.getBetSummary()

  var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])

  var betTime: [SharedBu.LocalDateTime] = []

  var section = 0

  var webGameResultDriver: Driver<WebGameResult> {
    webGameResultSubject.asDriverLogError()
  }

  var loadingWebTracker: ActivityIndicator { loading.tracker }

  let placeholderTracker = ActivityIndicator()
  
  private(set) var periodPaginationDic: [PeriodOfRecord: Pagination<BetRecord>] = [:]

  init(
    _ casinoRecordUseCase: CasinoRecordUseCase,
    _ casinoUseCase: CasinoUseCase,
    _ memoryCache: MemoryCacheImpl,
    _ casinoGameAppService: ICasinoGameAppService,
    _ casinoMyBetAppService: ICasinoMyBetAppService)
  {
    self.casinoRecordUseCase = casinoRecordUseCase
    self.casinoUseCase = casinoUseCase
    self.memoryCache = memoryCache
    self.casinoGameAppService = casinoGameAppService
    self.casinoMyBetAppService = casinoMyBetAppService
    
    super.init()

    if let tags: [GameFilter] = memoryCache.getGameTag(.casinoGameTag) {
      tagFilter.accept(tags.filter({ $0 is GameFilter.Tag }).map { $0 as! GameFilter.Tag }.map({
        ProductDTO.GameTag(id: $0.tag.type, name: $0.tag.name)
      }))
    }
  }

  func selectAll() {
    tagFilter.accept([])
    setCache(gameTags: [])
  }

  func toggleTag(_ tag: ProductDTO.GameTag) {
    var copyValue = tagFilter.value
    if let index = copyValue.firstIndex(of: tag) {
      copyValue.remove(at: index)
    }
    else {
      copyValue.append(tag)
    }
    tagFilter.accept(copyValue)
    setCache(gameTags: copyValue)
  }

  private func setCache(gameTags: [ProductDTO.GameTag]) {
    let gameFilters: [GameFilter] = gameTags.map({ GameFilter.Tag(tag: GameTag(type: $0.id, name: $0.name)) })
    memoryCache.setGameTag(.casinoGameTag, gameFilters)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - Game

extension CasinoViewModel {
  func getGameProduct() -> String { "casino" }

  func getGameProductType() -> ProductType {
    ProductType.casino
  }

  func lobby() -> Single<[CasinoLobby]> {
    casinoUseCase.getLobbies()
      .map {
        if $0.count > 0 {
          return $0.filter { $0.lobby != .none }
        }
        else {
          throw KTOError.EmptyData
        }
      }
      .trackOnDispose(placeholderTracker)
  }

  func getLobbyGames(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
    refreshTrigger
      .flatMapLatest { [unowned self] in
        self.searchGamesByLobby(lobby: lobby)
      }
  }

  func refreshLobbyGames() {
    refreshTrigger.onNext(())
  }

  private func getCasinoBetTypeTags() -> Observable<[CasinoGameTag]> {
    casinoUseCase.getCasinoBetTypeTags().asObservable().share(replay: 1)
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    casinoUseCase.checkBonusAndCreateGame(game)
  }

  func fetchGame(_ game: WebGame) {
    configFetchGame(
      game,
      resultSubject: webGameResultSubject,
      errorSubject: errorsSubject)
      .disposed(by: disposeBag)
  }
}

// MARK: - Favorite

extension CasinoViewModel {
  func getFavorites() {
    favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])

    casinoUseCase
      .getFavorites()
      .trackOnNext(placeholderTracker)
      .subscribe(onNext: { [weak self] games in
        if games.count > 0 {
          self?.favorites.onNext(games)
        }
        else {
          self?.favorites.onError(KTOError.EmptyData)
        }
      }, onError: { [weak self] in
        self?.favorites.onError($0)
      })
      .disposed(by: disposeBag)
  }

  func favoriteProducts() -> Observable<[WebGameWithDuplicatable]> {
    favorites.asObservable()
  }

  func toggleFavorite(
    game: WebGameWithDuplicatable,
    onCompleted: @escaping (FavoriteAction) -> Void,
    onError: @escaping (Error) -> Void)
  {
    if game.isFavorite {
      removeFavorite(game).subscribe(onCompleted: {
        onCompleted(.remove)
      }, onError: { error in
        onError(error)
      }).disposed(by: disposeBag)
    }
    else {
      addFavorite(game).subscribe(onCompleted: {
        onCompleted(.add)
      }, onError: { error in
        onError(error)
      }).disposed(by: disposeBag)
    }
  }

  private func addFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
    casinoUseCase.addFavorite(game: casinoGame)
  }

  private func removeFavorite(_ casinoGame: WebGameWithDuplicatable) -> Completable {
    casinoUseCase.removeFavorite(game: casinoGame)
  }
}

// MARK: - Search

extension CasinoViewModel {
  func clearSearchResult() {
    triggerSearch("")
  }

  func searchSuggestion() -> Single<[String]> {
    self.casinoUseCase.getSuggestKeywords()
  }

  func triggerSearch(_ keyword: String?) {
    guard let keyword else { return }
    self.searchKey.accept(SearchKeyword(keyword: keyword))
  }

  func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
    self.searchKey.flatMapLatest { [unowned self] keyword -> Observable<Event<[WebGameWithDuplicatable]>> in
      self.casinoUseCase.searchGames(keyword: keyword).materialize()
    }
  }

  func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
    casinoUseCase
      .searchGamesByLobby(lobby: lobby)
      .trackOnNext(placeholderTracker)
      .do(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
  }

  private func searchedCasinoByTag(tags: [ProductDTO.GameTag]) -> Observable<[CasinoGame]> {
    casinoUseCase
      .searchGamesByTag(tags: tags)
      .retry(3)
      .trackOnNext(placeholderTracker)
      .do(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
  }
}

// MARK: - Record

extension CasinoViewModel {
  func getUnsettledBetSummary() -> Observable<[UnsettledBetSummary]> {
    casinoRecordUseCase.getUnsettledSummary()
      .do(onSuccess: { [unowned self] in
        $0.forEach { self.betTime.append($0.betTime) }
      })
      .asObservable()
  }

  func getUnsettledRecords(betTime: SharedBu.LocalDateTime) -> Single<[SharedBu.LocalDateTime: [UnsettledBetRecord]]> {
    casinoRecordUseCase.getUnsettledRecords(date: betTime).map { [betTime: $0] }
  }

  func getUnsettledRecords() -> Observable<[SharedBu.LocalDateTime: [UnsettledBetRecord]]> {
    let allObservables = betTime.map { getUnsettledRecords(betTime: $0).asObservable() }
    return Observable.merge(allObservables)
  }

  func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]> {
    casinoRecordUseCase.getBetSummaryByDate(localDate: localDate)
      .do(onSuccess: { [unowned self] in
        self.setupPeriodPaginationDictionary(periodOfRecords: $0)
      })
  }
  
  private func setupPeriodPaginationDictionary(periodOfRecords: [PeriodOfRecord]) {
    periodPaginationDic = Dictionary(uniqueKeysWithValues: periodOfRecords.map { period in
      (period, Pagination<BetRecord>(
        startIndex: 0,
        offset: 20,
        observable: { [unowned self] currentIndex -> Observable<[BetRecord]> in
          self.getBetRecords(periodOfRecord: period, offset: currentIndex)
            .do(onError: { error in
              self.periodPaginationDic[period]?.error.onNext(error)
            }).catch({ _ -> Observable<[BetRecord]> in
              Observable.empty()
            })
        }))
    })
  }

  func getBetRecords(periodOfRecord: PeriodOfRecord, offset: Int) -> Observable<[BetRecord]> {
    casinoRecordUseCase.getBetRecords(periodOfRecord: periodOfRecord, offset: offset).asObservable()
  }
  
  func getWagerDetail(wagerId: String) -> Single<CasinoDTO.BetDetail> {
    Single.from(casinoMyBetAppService.getDetail(id: wagerId))
  }
}
