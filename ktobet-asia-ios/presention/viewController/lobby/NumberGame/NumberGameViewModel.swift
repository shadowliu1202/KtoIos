import Foundation
import RxCocoa
import RxSwift
import SharedBu

class NumberGameViewModel: CollectErrorViewModel, ProductViewModel {
  @Injected private var loading: Loading

  private let numberGameUseCase: NumberGameUseCase
  private let memoryCache: MemoryCacheImpl
  private let numberGameService: INumberGameAppService

  private let disposeBag = DisposeBag()

  private let webGameResultSubject = PublishSubject<WebGameResult>()

  private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))

  private lazy var gameTags = RxSwift.Single<NumberGameDTO.GameTags>.from(numberGameService.getTags()).asObservable()

  private lazy var filterSets: Observable<Set<GameFilter>> = Observable
    .combineLatest(tagFilter, recommendFilter, newFilter) { tags, recommand, new -> Set<GameFilter> in
      var gameFilters: Set<GameFilter> = Set(tags.map({
        GameFilter.Tag(tag: GameTag(type: $0.id, name: $0.name))
      }))
      if recommand { gameFilters.insert(GameFilter.Promote()) }
      if new { gameFilters.insert(GameFilter.New()) }
      return gameFilters
    }

  lazy var popularGames = numberGameUseCase
    .getPopularGames()
    .trackOnNext(placeholderTracker)

  lazy var allGames = Observable
    .combineLatest(gameSorting, filterSets)
    .flatMapLatest { [unowned self] gameSorting, gameFilters -> Observable<[NumberGame]> in
      self.numberGameUseCase
        .getGames(order: gameSorting, tags: gameFilters)
        .retry(3)
        .trackOnNext(self.placeholderTracker)
        .do(onError: {
          self.errorsSubject.onNext($0)
        })
    }

  private var tagFilter = BehaviorRelay<[ProductDTO.GameTag]>(value: [])
  private var recommendFilter = BehaviorRelay<Bool>(value: false)
  private var newFilter = BehaviorRelay<Bool>(value: false)

  lazy var tagStates = Observable
    .combineLatest(
      tagFilter,
      recommendFilter,
      newFilter,
      gameTags)
    .map { filter, isRecommend, isNew, gameTags in
      ((gameTags.recommendTag, isRecommend), (gameTags.newTag, isNew), gameTags.gameTags.map({ ($0, filter.contains($0)) }))
    }
    .compose(applyObservableErrorHandle())

  var favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])
  var gameSorting = BehaviorRelay<GameSorting>(value: .popular)

  var webGameResultDriver: Driver<WebGameResult> {
    webGameResultSubject.asDriverLogError()
  }

  var loadingWebTracker: ActivityIndicator { loading.tracker }

  let placeholderTracker = ActivityIndicator()

  init(numberGameUseCase: NumberGameUseCase, memoryCache: MemoryCacheImpl, numberGameService: INumberGameAppService) {
    self.numberGameUseCase = numberGameUseCase
    self.memoryCache = memoryCache
    self.numberGameService = numberGameService
    super.init()
    if let tags: [GameFilter] = memoryCache.getGameTag(.numberGameTag) {
      tagFilter.accept(tags.filter({ $0 is GameFilter.Tag }).map { $0 as! GameFilter.Tag }.map({
        ProductDTO.GameTag(id: $0.tag.type, name: $0.tag.name)
      }))
      if tags.contains(GameFilter.New()) {
        newFilter.accept(true)
      }
      if tags.contains(GameFilter.Promote()) {
        recommendFilter.accept(true)
      }
    }
  }

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
    }
    else {
      copyValue.append(tag)
    }
    tagFilter.accept(copyValue)
    setCache(gameTags: copyValue)
  }

  private func setCache(isRecommend: Bool? = nil, isNew: Bool? = nil, gameTags: [ProductDTO.GameTag]? = nil) {
    let filters: [GameFilter] = memoryCache.getGameTag(.numberGameTag) ?? []

    var recommend: Bool
    if isRecommend == nil {
      recommend = filters.contains(GameFilter.Promote())
    }
    else {
      recommend = isRecommend!
    }

    var new: Bool
    if isNew == nil {
      new = filters.contains(GameFilter.New())
    }
    else {
      new = isNew!
    }

    var gameFilters: [GameFilter]
    if gameTags == nil {
      gameFilters = filters.filter({ $0 is GameFilter.Tag })
    }
    else {
      gameFilters = gameTags!.map({ GameFilter.Tag(tag: GameTag(type: $0.id, name: $0.name)) })
    }

    if recommend { gameFilters.append(GameFilter.Promote()) }
    if new { gameFilters.append(GameFilter.New()) }

    memoryCache.setGameTag(.numberGameTag, gameFilters)
  }

  private func updateGameSorting() {
    if recommendFilter.value {
      updateGameSorting(sorting: .popular)
    }
    else if newFilter.value {
      updateGameSorting(sorting: .releaseddate)
    }
    else {
      updateGameSorting(sorting: .popular)
    }
  }

  func updateGameSorting(sorting: GameSorting) {
    gameSorting.accept(sorting)
  }
}

// MARK: - Game

extension NumberGameViewModel {
  func getGameProduct() -> String {
    "numbergame"
  }

  func getGameProductType() -> ProductType {
    ProductType.numbergame
  }

  private func getTags() -> Observable<[GameTag]> {
    numberGameUseCase.getGameTags().asObservable().share(replay: 1)
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    numberGameUseCase.checkBonusAndCreateGame(game)
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

extension NumberGameViewModel {
  func getFavorites() {
    favorites = BehaviorSubject<[WebGameWithDuplicatable]>(value: [])

    numberGameUseCase
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

  private func addFavorite(_ game: WebGameWithDuplicatable) -> Completable {
    numberGameUseCase.addFavorite(game: game)
  }

  private func removeFavorite(_ game: WebGameWithDuplicatable) -> Completable {
    numberGameUseCase.removeFavorite(game: game)
  }
}

// MARK: - Search

extension NumberGameViewModel {
  func clearSearchResult() {
    triggerSearch("")
  }

  func searchSuggestion() -> Single<[String]> {
    self.numberGameUseCase.getSuggestKeywords()
  }

  func triggerSearch(_ text: String?) {
    guard let txt = text else { return }
    self.searchKey.accept(SearchKeyword(keyword: txt))
  }

  func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
    self.searchKey.flatMapLatest { [unowned self] keyword -> Observable<Event<[WebGameWithDuplicatable]>> in
      self.numberGameUseCase.searchGames(keyword: keyword).materialize()
    }
  }
}
