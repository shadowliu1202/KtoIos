import Foundation
import share_bu
import RxSwift

protocol CasinoUseCase {
    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]>
    func getLobbies() -> Single<[CasinoLobby]>
    func createGame(gameId: Int32) -> Single<URL?>
    func addFavorite(casinoGame: CasinoGame) -> Completable
    func removeFavorite(casinoGame: CasinoGame) -> Completable
    func getFavorites() -> Single<[CasinoGame]>
    func searchGamesByTag(tags: [CasinoGameTag]) -> Observable<[CasinoGame]>
    func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]>
    func searchGamesByKeyword(keyword: SearchKeyword) -> Observable<[CasinoGame]>
    func getSuggestKeywords() -> Single<[String]>
}

class CasinoUseCaseImpl: CasinoUseCase {
    var casinoRepository: CasinoRepository!
    var localRepository: LocalStorageRepository!
    
    init(_ casinoRepository : CasinoRepository, _ localRepository: LocalStorageRepository) {
        self.casinoRepository = casinoRepository
        self.localRepository = localRepository
    }
    
    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]> {
        return casinoRepository.getTags(cultureCode: localRepository.getCultureCode()).map { (tags: [CasinoGameTag]) -> [CasinoGameTag] in
            tags.filter{ (tag: CasinoGameTag) -> Bool in
                return tag is CasinoGameTag.GameType
            }.sorted { (lhs, rhs) -> Bool in
                if lhs.id == 0 || rhs.id == 0 {
                    return true
                }
                return lhs.id < rhs.id 
            }
        }
    }
    
    func getLobbies() -> Single<[CasinoLobby]> {
        return casinoRepository.getLobby()
    }
    
    func searchGamesByTag(tags: [CasinoGameTag]) -> Observable<[CasinoGame]> {
        let lobbyIds = tags.filter { (tag: CasinoGameTag) -> Bool in
            return tag is CasinoGameTag.BelongTo
        }.map { (tag) -> Int32 in
            return tag.id
        }
        let typeIds = tags.filter { (tag: CasinoGameTag) -> Bool in
            return tag is CasinoGameTag.GameType
        }.map { (tag) -> Int32 in
            return tag.id
        }
        return casinoRepository.searchCasinoGame(lobbyIds: Set(lobbyIds), typeId: Set(typeIds))
    }
    
    func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
        let lobbyIds = CasinoLobbyType.Companion.init().convert(type: lobby)
        return casinoRepository.searchCasinoGame(lobbyIds: Set([lobbyIds]), typeId: [])
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return casinoRepository.getGameLocation(gameId: gameId)
    }
    
    func getFavorites() -> Single<[CasinoGame]> {
        return casinoRepository.getFavoriteCasino()
    }
    
    func addFavorite(casinoGame: CasinoGame) -> Completable {
        return casinoRepository.addFavoriteCasino(casino: casinoGame)
    }
    
    func removeFavorite(casinoGame: CasinoGame) -> Completable {
        return casinoRepository.removeFavoriteCasino(casino: casinoGame)
    }
    
    func searchGamesByKeyword(keyword: SearchKeyword) -> Observable<[CasinoGame]> {
        if keyword.isSearchPermitted() {
            return casinoRepository.searchCasinoGame(keyword: keyword)
        }
        return Observable.just([])
    }
    
    func getSuggestKeywords() -> Single<[String]> {
        return casinoRepository.getCasinoKeywordSuggestion()
    }
}
