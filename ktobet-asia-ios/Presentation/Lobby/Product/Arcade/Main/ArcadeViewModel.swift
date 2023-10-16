import Foundation
import RxCocoa
import RxSwift
import sharedbu

class ArcadeViewModel: CollectErrorViewModel, ProductViewModel {
  @Injected private var loading: Loading

  private let arcadeUseCase: ArcadeUseCase
  private let memoryCache: MemoryCacheImpl
  private let arcadeAppService: IArcadeAppService

  private let webGameResultSubject: PublishSubject<WebGameResult> = .init()

  private lazy var gameTags = RxSwift.Single<ArcadeDTO.GameTags>.from(arcadeAppService.getTags()).asObservable()
  private lazy var filterSets: Observable<(Bool, Bool)> = Observable.combineLatest(recommendFilter, newFilter) { ($0, $1) }

  private var searchKey = BehaviorRelay<SearchKeyword>(value: SearchKeyword(keyword: ""))
  private var disposeBag = DisposeBag()

  private var recommendFilter = BehaviorRelay<Bool>(value: false)
  private var newFilter = BehaviorRelay<Bool>(value: false)

  lazy var tagStates: Observable<((ProductDTO.RecommendTag?, Bool), (ProductDTO.NewTag?, Bool))> = Observable
    .combineLatest(recommendFilter, newFilter, gameTags).map({ isRecommend, isNew, gameTags in
      ((gameTags.recommendTag, isRecommend), (gameTags.newTag, isNew))
    }).compose(applyObservableErrorHandle())

  lazy var gameSource = filterSets
    .flatMapLatest { [unowned self] in
      self.searchedByFilter($0)
    }

  var loadingWebTracker: ActivityIndicator { loading.tracker }
  let placeholderTracker = ActivityIndicator()

  var webGameResultDriver: Driver<WebGameResult> {
    webGameResultSubject.asDriverLogError()
  }

  init(
    arcadeUseCase: ArcadeUseCase,
    memoryCache: MemoryCacheImpl,
    arcadeAppService: IArcadeAppService)
  {
    self.arcadeUseCase = arcadeUseCase
    self.memoryCache = memoryCache
    self.arcadeAppService = arcadeAppService

    super.init()

    if let tags: [GameFilter] = memoryCache.getGameTag(.arcadeGameTag) {
      if tags.contains(GameFilter.New()) {
        newFilter.accept(true)
      }
      if tags.contains(GameFilter.Promote()) {
        recommendFilter.accept(true)
      }
    }
  }

  func selectAll() {
    recommendFilter.accept(false)
    newFilter.accept(false)
    setCache(isRecommend: false, isNew: false)
  }

  func toggleRecommend() {
    let value = !recommendFilter.value
    recommendFilter.accept(value)
    setCache(isRecommend: value)
  }

  func toggleNew() {
    let value = !newFilter.value
    newFilter.accept(value)
    setCache(isNew: value)
  }

  private func setCache(isRecommend: Bool? = nil, isNew: Bool? = nil) {
    let filters: [GameFilter] = memoryCache.getGameTag(.arcadeGameTag) ?? []
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
    var gameFilters: [GameFilter] = []
    if recommend { gameFilters.append(GameFilter.Promote()) }
    if new { gameFilters.append(GameFilter.New()) }
    memoryCache.setGameTag(.arcadeGameTag, gameFilters)
  }
}

// MARK: - Game

extension ArcadeViewModel {
  func getGameProduct() -> String { "arcade" }

  func getGameProductType() -> ProductType {
    ProductType.arcade
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    arcadeUseCase.checkBonusAndCreateGame(game)
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

extension ArcadeViewModel {
  func favoriteProducts() -> Observable<[WebGameWithDuplicatable]> {
    arcadeUseCase.getFavorites()
      .trackOnNext(placeholderTracker)
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
    arcadeUseCase.addFavorite(game: game)
  }

  private func removeFavorite(_ game: WebGameWithDuplicatable) -> Completable {
    arcadeUseCase.removeFavorite(game: game)
  }
}

// MARK: - Search

extension ArcadeViewModel {
  func clearSearchResult() {
    triggerSearch("")
  }

  func searchSuggestion() -> Single<[String]> {
    arcadeUseCase.getSuggestKeywords()
  }

  func triggerSearch(_ text: String?) {
    guard let keyword = text else { return }
    self.searchKey.accept(SearchKeyword(keyword: keyword))
  }

  func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>> {
    self.searchKey.flatMapLatest { [unowned self] keyword -> Observable<Event<[WebGameWithDuplicatable]>> in
      self.arcadeUseCase.searchGames(keyword: keyword).materialize()
    }
  }

  private func searchedByFilter(_ filter: (Bool, Bool)) -> Observable<[ArcadeGame]> {
    arcadeUseCase
      .getGames(isRecommend: filter.0, isNew: filter.1)
      .retry(3)
      .trackOnNext(placeholderTracker)
      .do(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
  }
}
