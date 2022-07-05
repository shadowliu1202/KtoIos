import Foundation
import RxSwift
import RxCocoa
import SharedBu

protocol ArcadeRepository: WebGameRepository {
    func searchGames(tags: [GameFilter]) -> Observable<[ArcadeGame]>
}

class ArcadeRepositoryImpl: WebGameRepositoryImpl, ArcadeRepository {
    private var arcadeApi: ArcadeApi!
    private var httpClient: HttpClient!
    
    init(_ arcadeApi: ArcadeApi, httpClient: HttpClient) {
        super.init(arcadeApi, httpClient: httpClient)
        self.arcadeApi = arcadeApi
        self.httpClient = httpClient
    }
    
    func searchGames(tags: [GameFilter]) -> Observable<[ArcadeGame]> {
        var isRecommend: Bool = false
        var isNew: Bool = false
        tags.forEach { (tag) in
            switch tag {
            case is GameFilter.New:
                isNew = true
                break
            case is GameFilter.Promote:
                isRecommend = true
                break
            default:
                break
            }
        }
        var sort: Int32
        if isRecommend || (isRecommend && isNew) {
            sort = GameSorting.Companion.init().convert(sortBy: GameSorting.popular)
        } else if isNew {
            sort = GameSorting.Companion.init().convert(sortBy: GameSorting.releaseddate)
        } else {
            sort = GameSorting.Companion.init().convert(sortBy: GameSorting.popular)
        }
        let fetchApi = arcadeApi.searchGames(sortBy: sort, isRecommend: isRecommend, isNew: isNew)
            .asObservable()
            .map { [unowned self] (response) -> [ArcadeGame] in
            guard let data = response.data else {return []}
                return data.map { $0.toArcadeGame(host: self.httpClient.host.absoluteString) }
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game as! ArcadeGame
                }
            }
            return duplicateGames
        }
    }

    override func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = arcadeApi.getFavoriteArcade().map({ [unowned self] (response) -> [WebGameWithDuplicatable] in
            guard let data = response.data else { return [] }
            return data.map { $0.toArcadeGame(host: self.httpClient.host.absoluteString) }
        })
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }
    
    override func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = arcadeApi.searchGames(keyword: keyword.getKeyword()).map { [unowned self] (response) -> [WebGameWithDuplicatable] in
            guard let data = response.data else { return [] }
            return data.map { $0.toArcadeGame(host: self.httpClient.host.absoluteString) }
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }
    
}
