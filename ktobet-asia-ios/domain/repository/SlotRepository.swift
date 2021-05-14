import Foundation
import RxSwift
import RxCocoa
import share_bu

protocol SlotRepository {
    func getFavoriteSlots() -> Single<[SlotGame]>
    func addFavoriteSlot(slotGame: SlotGame) -> Completable
    func removeFavoriteSlot(slotGame: SlotGame) -> Completable
    func getPopularGames() -> Observable<SlotHotGames>
    func getRecentlyPlaySlots() -> Observable<[SlotGame]>
    func searchSlotGame(keyword: SearchKeyword) -> Observable<[SlotGame]>
    func getSlotKeywordSuggestion() -> Single<[String]>
    func getNewAndJackpotGames() -> Observable<SlotNewAndJackpotGames>
    func searchSlot(sortBy: GameSorting,
                    isJackpot: Bool,
                    isNew: Bool,
                    featureTags: Set<SlotGameFilter.SlotGameFeature>,
                    themeTags: Set<SlotGameFilter.SlotGameTheme>,
                    payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<[SlotGame]>
    func gameCount(isJackpot: Bool,
                   isNew: Bool,
                   featureTags: Set<SlotGameFilter.SlotGameFeature>,
                   themeTags: Set<SlotGameFilter.SlotGameTheme>,
                   payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<Int>
    func getGameLocation(gameId: Int32) -> Single<URL?>
}

class SlotRepositoryImpl: SlotRepository {
    private let favoriteRecord = BehaviorRelay<[SlotGame]>(value: [])
    private var slotApi: SlotApi!
    
    init(_ slotApi: SlotApi) {
        self.slotApi = slotApi
    }
    
    func getFavoriteSlots() -> Single<[SlotGame]> {
        return slotApi.getFavoriteSlots().map {(response) -> [SlotGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toSlotGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
    }
    
    func addFavoriteSlot(slotGame: SlotGame) -> Completable {
        return slotApi.addFavoriteCasino(id: slotGame.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == slotGame.gameId}) {
                copyValue[i] = SlotGame.duplicateGame(slotGame, isFavorite: true)
            } else {
                let game = SlotGame.duplicateGame(slotGame, isFavorite: true)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func removeFavoriteSlot(slotGame: SlotGame) -> Completable {
        return slotApi.removeFavoriteCasino(id: slotGame.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == slotGame.gameId}) {
                copyValue[i] = SlotGame.duplicateGame(slotGame, isFavorite: false)
            } else {
                let game = SlotGame.duplicateGame(slotGame, isFavorite: false)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func getPopularGames() -> Observable<SlotHotGames> {
        let fetchApi = slotApi.getHotGame().map { (response) -> SlotHotGames in
            guard let data = response.data else { return SlotHotGames(mostTransactionRanking: [], mostWinningAmountRanking: []) }
            return data.toSlotHotGames(portalHost: HttpClient.init().getHost())
        }.asObservable()
        
        return Observable.combineLatest(favoriteRecord.asObservable(), fetchApi).map { (favorites, games) -> SlotHotGames in
            return SlotHotGames(mostTransactionRanking: self.updateSourceByFavorite(games.mostTransactionRanking, favorites),
                                mostWinningAmountRanking: self.updateSourceByFavorite(games.mostWinningAmountRanking, favorites))
        }
    }
    
    func getRecentlyPlaySlots() -> Observable<[SlotGame]> {
        let fetchApi = slotApi.getRecentGames().map { (response) -> [SlotGame] in
            guard let data = response.data else { return [] }
            return data.map{ $0.toSlotGame(portalHost: HttpClient.init().getHost()) }
        }.asObservable()
        
        return Observable.combineLatest(favoriteRecord.asObservable(), fetchApi).map { (favorites, games) -> [SlotGame] in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    func getNewAndJackpotGames() -> Observable<SlotNewAndJackpotGames> {
        let fetchApi = slotApi.getNewAndJackpotGames().map { (response) -> SlotNewAndJackpotGames in
            guard let data = response.data else { return SlotNewAndJackpotGames(newGame: [], jackpotGames: [])}
            return data.toSlotNewAndJackpotGames(portalHost: HttpClient.init().getHost())
        }.asObservable()
        
        return Observable.combineLatest(favoriteRecord.asObservable(), fetchApi).map { (favorites, games) -> SlotNewAndJackpotGames in
            return SlotNewAndJackpotGames(newGame: self.updateSourceByFavorite(games.newGame, favorites),
                                          jackpotGames: self.updateSourceByFavorite(games.jackpotGames, favorites))
        }
    }
    
    func searchSlotGame(keyword: SearchKeyword) -> Observable<[SlotGame]> {
        let fetchApi =  slotApi.searchSlot(keyword: keyword.getKeyword()).map {(response) -> [SlotGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toSlotGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
        
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    func searchSlot(sortBy: GameSorting,
                    isJackpot: Bool,
                    isNew: Bool,
                    featureTags: Set<SlotGameFilter.SlotGameFeature>,
                    themeTags: Set<SlotGameFilter.SlotGameTheme>,
                    payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<[SlotGame]> {
        let fetchApi = slotApi.search(sortBy: GameSorting.Companion.init().convert(sortBy: sortBy),
                              isJackpot: isJackpot,
                              isNew: isNew,
                              featureTags: MultiSelection<SlotGameFilter.SlotGameFeature>(list: featureTags).getDecimalPresentation(),
                              themeTags: MultiSelection<SlotGameFilter.SlotGameTheme>(list: themeTags).getDecimalPresentation(),
                              payLineWayTags: MultiSelection<SlotGameFilter.SlotPayLineWay>(list: payLineWayTags).getDecimalPresentation())
            .map { (response) -> [SlotGame] in
                guard let data = response.data else { return [] }
                return data.map{ $0.toSlotGame(portalHost: HttpClient.init().getHost()) }
            }.asObservable()
        
        return Observable.combineLatest(favoriteRecord.asObservable(), fetchApi).map { (favorites, games) -> [SlotGame] in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    func gameCount(isJackpot: Bool,
                   isNew: Bool,
                   featureTags: Set<SlotGameFilter.SlotGameFeature>,
                   themeTags: Set<SlotGameFilter.SlotGameTheme>,
                   payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<Int> {
        return slotApi.gameCount(sortBy: GameSorting.Companion.init().convert(sortBy: .popular),
                                 isJackpot: isJackpot, isNew: isNew,
                                 featureTags: MultiSelection<SlotGameFilter.SlotGameFeature>(list: featureTags).getDecimalPresentation(),
                                 themeTags: MultiSelection<SlotGameFilter.SlotGameTheme>(list: themeTags).getDecimalPresentation(),
                                 payLineWayTags: MultiSelection<SlotGameFilter.SlotPayLineWay>(list: payLineWayTags).getDecimalPresentation())
            .map { (response) -> Int in
                guard let data = response.data else { return 0 }
                return data
            }.asObservable()
    }
    
    func getSlotKeywordSuggestion() -> Single<[String]> {
        return slotApi.slotKeywordSuggestion().map { (response) -> [String] in
            if let suggestions = response.data {
                return suggestions
            }
            return []
        }
    }
    
    private func updateSourceByFavorite(_ games: [SlotGame], _ favorites: [SlotGame]) -> [SlotGame] {
        var duplicateGames = games
        favorites.forEach { (favoriteItem) in
            if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                duplicateGames[i] = SlotGame.duplicateGame(favoriteItem, isFavorite: favoriteItem.isFavorite)
            }
        }
        
        return duplicateGames
    }
    
    func getGameLocation(gameId: Int32) -> Single<URL?> {
        return slotApi.getGameUrl(gameId: gameId, siteUrl: KtoURL.baseUrl.absoluteString).map { (response) -> URL? in
            if let path = response.data, let url = URL(string: path) {
                return url
            }
            return nil
        }
    }
}
