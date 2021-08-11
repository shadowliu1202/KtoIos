import Foundation
import RxSwift
import RxCocoa
import SharedBu

protocol CasinoRepository: WebGameRepository {
    func getTags(cultureCode: String) -> Single<[CasinoGameTag]>
    func getLobby() -> Single<[CasinoLobby]>
    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]>
}

class CasinoRepositoryImpl: WebGameRepositoryImpl, CasinoRepository {
    private var casinoApi: CasinoApi!
    
    init(_ casinoApi: CasinoApi) {
        super.init(casinoApi)
        self.casinoApi = casinoApi
    }
    
    func getTags(cultureCode: String) -> Single<[CasinoGameTag]> {
        return casinoApi.getCasinoTags(culture: cultureCode).map { (response) -> [CasinoGameTag] in
            var tags: [CasinoGameTag] = []
            if let data0 = response.data["0"] {
                tags.append(contentsOf: data0.map({CasinoGameTag.GameType(id: Int32($0.id), name: $0.name)}))
            }
            if let data1 = response.data["1"] {
                tags.append(contentsOf: data1.map({CasinoGameTag.BelongTo(id: Int32($0.id), name: $0.name)}))
            }
            return tags
        }
    }
    func getLobby() -> Single<[CasinoLobby]> {
        return casinoApi.getCasinoGames().map { (response) -> [CasinoLobby] in
            return response.data.map { (bean) -> CasinoLobby in
                let lobby = CasinoLobbyType.Companion.init().convert(type_: Int32(bean.lobbyID))
                return CasinoLobby(lobby: lobby, name: bean.lobbyName, isMaintenance: bean.isLobbyMaintenance)
            }
        }
    }
    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]> {
        var map: [String: String] = [:]
        lobbyIds.enumerated().forEach { (index, element) in map["lobbyIds[\(index)]"] = String(element) }
        typeId.enumerated().forEach { (index, element) in map["gameTags[\(index)]"] = String(element) }
        let fetchApi =  casinoApi.search(sortBy: GameSorting.convertCasinoGameOrder(sortBy: GameSorting.releaseddate), map: map).map {  (response) -> [CasinoGame] in
            guard let data = response.data else { return [] }
            return data.map({ $0.toCasinoGame() })
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game as! CasinoGame
                }
            }
            return duplicateGames
        }
    }
    override func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = casinoApi.getFavoriteCasinos().map({ (response) -> [WebGameWithDuplicatable] in
            guard let data = response.data else { return [] }
            return data.map { $0.toCasinoGame() }
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
        let fetchApi =  casinoApi.searchCasino(keyword: keyword.getKeyword()).map { (response) -> [WebGameWithDuplicatable] in
            guard let data = response.data else { return [] }
            return data.map { $0.toCasinoGame() }
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

