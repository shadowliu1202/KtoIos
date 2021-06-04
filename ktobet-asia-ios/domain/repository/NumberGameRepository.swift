import Foundation
import RxSwift
import RxCocoa
import SharedBu

protocol NumberGameRepository {
    func addFavorite(game: NumberGame) -> Completable
    func removeFavorite(game: NumberGame) -> Completable
    func getFavorites() -> Single<[NumberGame]>
    func getKeywordSuggestion() -> Single<[String]>
    func searchGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]>
    func searchGames(keyword: SearchKeyword) -> Observable<[NumberGame]>
    func getTags() -> Single<[GameTag]>
    func createGame(gameId: Int32) -> Single<URL?>
    func getPopularGames() -> Observable<HotNumberGames>
}

class NumberGameRepositoryImpl: NumberGameRepository {
    private let favoriteRecord = BehaviorRelay<[NumberGame]>(value: [])
    private var numberGameApi: NumberGameApi!
    
    init(_ numberGameApi: NumberGameApi) {
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
                    let game = NumberGame.duplicateGame(duplicateGames[i], isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game
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
    
    func addFavorite(game: NumberGame) -> Completable {
        return numberGameApi.addFavorite(id: game.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == game.gameId}) {
                copyValue[i] = NumberGame.duplicateGame(game, isFavorite: true)
            } else {
                let game = NumberGame.duplicateGame(game, isFavorite: true)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func removeFavorite(game: NumberGame) -> Completable {
        return numberGameApi.removeFavorite(id: game.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == game.gameId}) {
                copyValue[i] = NumberGame.duplicateGame(game, isFavorite: false)
            } else {
                let game = NumberGame.duplicateGame(game, isFavorite: false)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }

    func getFavorites() -> Single<[NumberGame]> {
        return numberGameApi.getFavorite().map { (response) -> [NumberGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toNumberGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
    }
    
    func getKeywordSuggestion() -> Single<[String]> {
        return numberGameApi.keywordSuggestions().map { (response) -> [String] in
            if let suggestions = response.data {
                return suggestions
            }
            return []
        }
    }
    
    func searchGames(keyword: SearchKeyword) -> Observable<[NumberGame]> {
        let fetchApi =  numberGameApi.searchKeyword(keyword: keyword.getKeyword()).map {(response) -> [NumberGame] in
            guard let data = response.data else { return [] }
            return data.map { $0.toNumberGame(portalHost: KtoURL.baseUrl.absoluteString) }
        }
        
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            return self.updateSourceByFavorite(games, favorites)
        }
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return numberGameApi.getGameUrl(gameId: gameId, siteUrl: KtoURL.baseUrl.absoluteString).map { (response) -> URL? in
            if let path = response.data, let url = URL(string: path) {
                return url
            }
            return nil
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
    
    private func updateSourceByFavorite(_ games: [NumberGame], _ favorites: [NumberGame]) -> [NumberGame] {
        var duplicateGames = games
        favorites.forEach { (favoriteItem) in
            if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                duplicateGames[i] = NumberGame.duplicateGame(favoriteItem, isFavorite: favoriteItem.isFavorite)
            }
        }
        
        return duplicateGames
    }
}
