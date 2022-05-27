import Foundation
import SharedBu
import RxSwift

protocol CasinoUseCase: WebGameUseCase {
    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]>
    func getLobbies() -> Single<[CasinoLobby]>
    func searchGamesByTag(tags: [CasinoGameTag]) -> Observable<[CasinoGame]>
    func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]>
}

class CasinoUseCaseImpl: WebGameUseCaseImpl, CasinoUseCase {
    var casinoRepository: CasinoRepository!
    var localStorageRepo: PlayerLocaleConfiguration!
    
    init(_ casinoRepository : CasinoRepository, _ localStorageRepo: PlayerLocaleConfiguration) {
        super.init(casinoRepository)
        self.casinoRepository = casinoRepository
        self.localStorageRepo = localStorageRepo
    }
    
    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]> {
        return casinoRepository.getTags(cultureCode: localStorageRepo.getCultureCode()).map { (tags: [CasinoGameTag]) -> [CasinoGameTag] in
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
}
