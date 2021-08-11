import Foundation
import RxSwift
import RxCocoa
import SharedBu

protocol SlotRepository: WebGameRepository {
    func getPopularGames() -> Observable<SlotHotGames>
    func getRecentlyPlaySlots() -> Observable<[SlotGame]>
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
}

class SlotRepositoryImpl: WebGameRepositoryImpl, SlotRepository {
    private var slotApi: SlotApi!
    
    init(_ slotApi: SlotApi) {
        super.init(slotApi)
        self.slotApi = slotApi
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
    
    override func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = slotApi.getFavoriteSlots().map({ (response) -> [SlotGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toSlotGame(portalHost: KtoURL.baseUrl.absoluteString) }
        })
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [unowned self] (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    override func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = slotApi.searchSlot(keyword: keyword.getKeyword()).map {(response) -> [SlotGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toSlotGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [unowned self] (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    private func updateSourceByFavorite(_ games: [SlotGame], _ favorites: [WebGameWithDuplicatable]) -> [SlotGame] {
        var duplicateGames = games
        favorites.forEach { (favoriteItem) in
            if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                duplicateGames[i] = game as! SlotGame
            }
        }
        
        return duplicateGames
    }
}
