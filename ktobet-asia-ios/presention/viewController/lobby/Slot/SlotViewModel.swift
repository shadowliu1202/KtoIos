import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import SharedBu

class SlotViewModel: CollectErrorViewModel, ProductViewModel {
  @Injected private var loading: Loading

  private let webGameResultSubject = PublishSubject<WebGameResult>()
  private let disposeBag = DisposeBag()

  private var slotUseCase: SlotUseCase!
  private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
  private var gameCountFilters = BehaviorRelay<[SlotGameFilter]>(value: [])

  lazy var popularGames = slotUseCase
    .getPopularSlots()
    .trackOnNext(placeholderTracker)

  lazy var recentGames = slotUseCase
    .getRecentlyPlaySlots()
    .trackOnNext(placeholderTracker)

  lazy var newGames = slotUseCase
    .getNewSlots()
    .trackOnNext(placeholderTracker)

  lazy var jackpotGames = slotUseCase
    .getJackpotSlots()
    .trackOnNext(placeholderTracker)

  lazy var gameCountWithSearchFilters = gameCountFilters
    .flatMap({ [unowned self] _ in self.gameCount })
    .map {
      ($0, self.gameCountFilters.value)
    }

  lazy var gameCount = gameCountFilters.flatMapLatest { filters -> Observable<Int> in
    let featureTags: Set<SlotGameFilter.SlotGameFeature> = Set(
      filters.filter { $0 is SlotGameFilter.SlotGameFeature }
        .map { $0 as! SlotGameFilter.SlotGameFeature })
    let themeTags: Set<SlotGameFilter.SlotGameTheme> = Set(
      filters.filter { $0 is SlotGameFilter.SlotGameTheme }
        .map { $0 as! SlotGameFilter.SlotGameTheme })
    let payLineWayTags: Set<SlotGameFilter.SlotPayLineWay> = Set(
      filters.filter { $0 is SlotGameFilter.SlotPayLineWay }
        .map { $0 as! SlotGameFilter.SlotPayLineWay })
    return self.slotUseCase.gameCount(
      isJackpot: false,
      isNew: false,
      featureTags: featureTags,
      themeTags: themeTags,
      payLineWayTags: payLineWayTags)
  }

  var slotFilter = BehaviorRelay<[SlotGameFilter]>(value: [])
  var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
  var webGameResultDriver: Driver<WebGameResult> {
    webGameResultSubject.asDriverLogError()
  }

  var loadingWebTracker: ActivityIndicator { loading.tracker }

  let placeholderTracker = ActivityIndicator()

  init(slotUseCase: SlotUseCase) {
    self.slotUseCase = slotUseCase
  }

  func setOptions(filter: [SlotGameFilter]) {
    gameCountFilters.accept(filter)
    slotFilter.accept(filter)
  }
}

// MARK: - Game

extension SlotViewModel {
  func getGameProduct() -> String { "slot" }

  func getGameProductType() -> ProductType {
    ProductType.slot
  }

  func gatAllGame(sorting: GameSorting, filters: [SlotGameFilter] = []) -> Observable<[SlotGame]> {
    let featureTags: Set<SlotGameFilter.SlotGameFeature> = Set(
      filters.filter { $0 is SlotGameFilter.SlotGameFeature }
        .map { $0 as! SlotGameFilter.SlotGameFeature })
    let themeTags: Set<SlotGameFilter.SlotGameTheme> = Set(
      filters.filter { $0 is SlotGameFilter.SlotGameTheme }
        .map { $0 as! SlotGameFilter.SlotGameTheme })
    let payLineWayTags: Set<SlotGameFilter.SlotPayLineWay> = Set(
      filters.filter { $0 is SlotGameFilter.SlotPayLineWay }
        .map { $0 as! SlotGameFilter.SlotPayLineWay })

    return self.slotUseCase.searchSlot(
      sortBy: sorting,
      isJackpot: false,
      isNew: false,
      featureTags: featureTags,
      themeTags: themeTags,
      payLineWayTags: payLineWayTags)
      .trackOnNext(placeholderTracker, resetWhenSubscribe: false)
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    slotUseCase.checkBonusAndCreateGame(game)
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

extension SlotViewModel {
  func getFavorites() {
    favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])

    slotUseCase
      .getFavorites()
      .trackOnNext(placeholderTracker)
      .subscribe(onNext: { [weak self] games in
        if games.count > 0 {
          self?.favorites.onNext(games)
        }
        else {
          self?.favorites.onError(KTOError.EmptyData)
        }
      }, onError: { [weak self] e in
        self?.favorites.onError(e)
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

  private func addFavorite(_ slotGame: WebGameWithDuplicatable) -> Completable {
    slotUseCase.addFavorite(game: slotGame)
  }

  private func removeFavorite(_ slotGame: WebGameWithDuplicatable) -> Completable {
    slotUseCase.removeFavorite(game: slotGame)
  }
}

// MARK: - Search

extension SlotViewModel {
  func clearSearchResult() {
    triggerSearch("")
  }

  func searchSuggestion() -> Single<[String]> {
    self.slotUseCase.getSuggestKeywords()
  }

  func triggerSearch(_ keyword: String?) {
    guard let keyword else { return }
    self.searchKey.accept(SearchKeyword(keyword: keyword))
  }

  func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
    self.searchKey.flatMapLatest { [unowned self] keyword -> Observable<Event<[WebGameWithDuplicatable]>> in
      self.slotUseCase.searchGames(keyword: keyword).materialize()
    }
  }
}
