import Foundation
import RxCocoa
import RxSwift
import sharedbu

protocol CasinoRepository: WebGameRepository {
    func getTags(cultureCode: String) -> Single<[CasinoGameTag]>
    func getLobby() -> Single<[CasinoLobby]>
    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]>
}

class CasinoRepositoryImpl: WebGameRepositoryImpl, CasinoRepository {
    private var casinoApi: CasinoApi!
    private var httpClient: HttpClient!

    init(_ casinoApi: CasinoApi, httpClient: HttpClient) {
        super.init(casinoApi, httpClient: httpClient)
        self.casinoApi = casinoApi
        self.httpClient = httpClient
    }

    func getTags(cultureCode: String) -> Single<[CasinoGameTag]> {
        casinoApi.getCasinoTags(culture: cultureCode).map { response -> [CasinoGameTag] in
            var tags: [CasinoGameTag] = []
            if let data0 = response.data["0"] {
                tags.append(contentsOf: data0.map({ CasinoGameTag.GameType(id: Int32($0.id), name: $0.name) }))
            }
            if let data1 = response.data["1"] {
                tags.append(contentsOf: data1.map({ CasinoGameTag.BelongTo(id: Int32($0.id), name: $0.name) }))
            }
            return tags
        }
    }

    func getLobby() -> Single<[CasinoLobby]> {
        casinoApi.getCasinoGames().map { response -> [CasinoLobby] in
            response.data.map { bean -> CasinoLobby in
                let lobby = CasinoLobbyType.Companion().convert(type: Int32(bean.lobbyID))
                return CasinoLobby(lobby: lobby, name: bean.lobbyName, isMaintenance: bean.isLobbyMaintenance)
            }
        }
    }

    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]> {
        var map: [String: String] = [:]
        lobbyIds.enumerated().forEach { index, element in map["lobbyIds[\(index)]"] = String(element) }
        typeId.enumerated().forEach { index, element in map["gameTags[\(index)]"] = String(element) }
        let fetchApi = casinoApi.search(sortBy: GameSorting.convertCasinoGameOrder(sortBy: GameSorting.releasedDate), map: map)
            .map { [unowned self] response -> [CasinoGame] in
                guard let data = response.data else { return [] }
                return try data.map({ try $0.toCasinoGame(host: self.httpClient.host.absoluteString) })
            }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { favorites, games in
            var duplicateGames = games
            for favoriteItem in favorites {
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId }) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game as! CasinoGame
                }
            }
            return duplicateGames
        }
    }

    override func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = casinoApi.getFavoriteCasinos().map({ [unowned self] response -> [WebGameWithDuplicatable] in
            guard let data = response.data else { return [] }
            return try data.map { try $0.toCasinoGame(host: self.httpClient.host.absoluteString) }
        })
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { favorites, games in
            var duplicateGames = games
            for favoriteItem in favorites {
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId }) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }

    override func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        let fetchApi = casinoApi.searchCasino(keyword: keyword.getKeyword())
            .map { [unowned self] response -> [WebGameWithDuplicatable] in
                guard let data = response.data else { return [] }
                return try data.map { try $0.toCasinoGame(host: self.httpClient.host.absoluteString) }
            }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { favorites, games in
            var duplicateGames = games
            for favoriteItem in favorites {
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId }) {
                    let game = duplicateGames[i].duplicate(isFavorite: favoriteItem.isFavorite)
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }
}
