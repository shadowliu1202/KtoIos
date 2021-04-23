import Foundation
import RxSwift
import RxCocoa
import share_bu

typealias GameId = Int32

protocol CasinoRepository {
    func getTags(cultureCode: String) -> Single<[CasinoGameTag]>
    func getLobby() -> Single<[CasinoLobby]>
    func getGameLocation(gameId: Int32) -> Single<URL?>
    func getFavoriteCasino() -> Single<[CasinoGame]>
    func addFavoriteCasino(casino: CasinoGame) -> Completable
    func removeFavoriteCasino(casino: CasinoGame) -> Completable
    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]>
    func searchCasinoGame(keyword: SearchKeyword) -> Observable<[CasinoGame]>
    func getCasinoKeywordSuggestion() -> Single<[String]>
}

class CasinoRepositoryImpl: CasinoRepository {
    private let favoriteRecord = BehaviorRelay<[CasinoGame]>(value: [])
    private var casinoApi: CasinoApi!
    
    init(_ casinoApi: CasinoApi) {
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
    func getGameLocation(gameId: Int32) -> Single<URL?> {
        return casinoApi.getGameUrl(gameId: gameId, siteUrl: KtoURL.baseUrl.absoluteString).map { (response) -> URL? in
            if let path = response.data, let url = URL(string: path) {
                return url
            }
            return nil
        }
    }
    
    private func createCasino(data: CasinoData) -> CasinoGame {
        let thumbnail = CasinoThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: data.imageID)
        return CasinoGame(gameId: Int32(data.gameID), gameName: data.name, isFavorite: data.isFavorite, gameStatus: GameStatus.convertToGameStatus(data.isGameMaintenance, data.status), thumbnail: thumbnail, releaseDate: data.releaseDate?.toLocalDate())
    }
    
    private func createCasinos(_ response: ResponseData<[CasinoData]>) -> [CasinoGame] {
        if let data = response.data {
            return data.map { self.createCasino(data: $0) }
        }
        return []
    }
    
    func getFavoriteCasino() -> Single<[CasinoGame]> {
        return casinoApi.getFavoriteCasinos().map { [weak self] (response) -> [CasinoGame] in
            guard let `self` = self else { return [] }
            return self.createCasinos(response)
        }
    }
    
    func addFavoriteCasino(casino: CasinoGame) -> Completable {
        return casinoApi.addFavoriteCasino(id: casino.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == casino.gameId}) {
                copyValue[i] = self.duplicateGame(casino, isFavorite: true)
            } else {
                let game = self.duplicateGame(casino, isFavorite: true)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func removeFavoriteCasino(casino: CasinoGame) -> Completable {
        return casinoApi.removeFavoriteCasino(id: casino.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == casino.gameId}) {
                copyValue[i] = self.duplicateGame(casino, isFavorite: false)
            } else {
                let game = self.duplicateGame(casino, isFavorite: false)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func searchCasinoGame(lobbyIds: Set<Int32>, typeId: Set<Int32>) -> Observable<[CasinoGame]> {
        var map: [String: String] = [:]
        lobbyIds.enumerated().forEach { (index, element) in map["lobbyIds[\(index)]"] = String(element) }
        typeId.enumerated().forEach { (index, element) in map["gameTags[\(index)]"] = String(element) }
        let fetchApi =  casinoApi.search(sortBy: GameSorting.convertCasinoGameOrder(sortBy: GameSorting.releaseddate), map: map).map { [weak self] (response) -> [CasinoGame] in
            guard let `self` = self else { return [] }
            return self.createCasinos(response)
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [weak self] (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}),
                   let game = self?.duplicateGame(favoriteItem, isFavorite: favoriteItem.isFavorite) {
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }
    
    func searchCasinoGame(keyword: SearchKeyword) -> Observable<[CasinoGame]> {
        let fetchApi =  casinoApi.searchCasino(keyword: keyword.getKeyword()).map { [weak self] (response) -> [CasinoGame] in
            guard let `self` = self else { return [] }
            return self.createCasinos(response)
        }
        return Observable.combineLatest(favoriteRecord, fetchApi.asObservable()) { [weak self] (favorites, games) in
            var duplicateGames = games
            favorites.forEach { (favoriteItem) in
                if let i = duplicateGames.firstIndex(where: { $0.gameId == favoriteItem.gameId}),
                   let game = self?.duplicateGame(favoriteItem, isFavorite: favoriteItem.isFavorite) {
                    duplicateGames[i] = game
                }
            }
            return duplicateGames
        }
    }
    
    func getCasinoKeywordSuggestion() -> Single<[String]> {
        return casinoApi.casinoKeywordSuggestion().map { (response) -> [String] in
            if let suggestions = response.data {
                return suggestions
            }
            return []
        }
    }
    
    private func duplicateGame(_ origin: CasinoGame, isFavorite: Bool) -> CasinoGame {
        return CasinoGame(gameId: origin.gameId, gameName: origin.gameName, isFavorite: isFavorite, gameStatus: origin.gameStatus, thumbnail: origin.thumbnail, releaseDate: origin.releaseDate)
    }
    
}

