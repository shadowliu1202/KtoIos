import Foundation
import RxSwift
import RxCocoa
import SharedBu

protocol NumberGameRepository: WebGameRepository {
    func searchGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]>
    func getTags() -> Single<[GameTag]>
    func getPopularGames() -> Observable<HotNumberGames>
}

class NumberGameRepositoryImpl: WebGameRepositoryImpl, NumberGameRepository {
    private var numberGameApi: NumberGameApi!
    
    init(_ numberGameApi: NumberGameApi) {
        super.init(numberGameApi)
        self.numberGameApi = numberGameApi
    }
    
    func searchGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]> {
        let isRecommand = tags.filter{ $0 is GameFilter.Promote }.count != 0
        let isNew = tags.filter{ $0 is GameFilter.New }.count != 0
        
        var map: [String: String] = [:]
        var index = 0
        tags.forEach { (gameFilter) in
            if let tag = gameFilter as? GameFilter.Tag {
                map["gameTags[\(index)]"] = "\(tag.tag.type)"
                index += 1
            }
        }
        
        let fetchApi = numberGameApi.searchGames(sortBy: order.ordinal, isRecommend: isRecommand, isNew: isNew, map: map).map { (response) -> [NumberGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toNumberGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }.asObservable()
        
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game as! NumberGame
                }
            }
            return duplicateGames
        }
    }
    
    func getTags() -> Single<[GameTag]> {
        return numberGameApi.getTags().map { (response) -> [GameTag] in
            var tags: [GameTag] = []
            if let data0 = response.data["0"] {
                tags.append(contentsOf: data0.map({GameTag(type: Int32($0.id), name: $0.name)}))
            }
            if let data1 = response.data["1"] {
                tags.append(contentsOf: data1.map({GameTag(type: Int32($0.id), name: $0.name)}))
            }
            return tags
        }
    }
    
    func getPopularGames() -> Observable<HotNumberGames> {
        let fetchApi = numberGameApi.getHotGame().map { (response) -> HotNumberGames in
            guard let data = response.data else { return HotNumberGames(betCountRanking: [], winLossRanking: []) }
            return data.toHotNumberGames(portalHost: HttpClient.init().getHost())
        }.asObservable()
        
        return Observable.combineLatest(favoriteRecord.asObservable(), fetchApi).map { (favorites, games) -> HotNumberGames in
            return HotNumberGames(betCountRanking: self.updateSourceByFavorite(games.betCountRanking, favorites),
                                  winLossRanking: self.updateSourceByFavorite(games.winLossRanking, favorites))
        }
    }
    
    override func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = numberGameApi.getFavorite().map({ (response) -> [NumberGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toNumberGame(portalHost: KtoURL.baseUrl.absoluteString) }
        })
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [unowned self] (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    override func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi =  numberGameApi.searchKeyword(keyword: keyword.getKeyword()).map {(response) -> [NumberGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toNumberGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [unowned self] (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    private func updateSourceByFavorite(_ games: [NumberGame], _ favorites: [WebGameWithDuplicatable]) -> [NumberGame] {
        var duplicateGames = games
        favorites.forEach { (favoriteItem) in
            if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                duplicateGames[i] = game as! NumberGame 
            }
        }
        
        return duplicateGames
    }
}
