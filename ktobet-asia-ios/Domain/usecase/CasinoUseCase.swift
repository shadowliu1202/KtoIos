import Foundation
import RxSwift
import sharedbu

protocol CasinoUseCase: WebGameUseCase {
    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]>
    func getLobbies() -> Single<[CasinoLobby]>
    func searchGamesByTag(tags: [ProductDTO.GameTag]) -> Observable<[CasinoGame]>
    func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]>
}

class CasinoUseCaseImpl: WebGameUseCaseImpl, CasinoUseCase {
    private let casinoRepository: CasinoRepository
    private let playerConfiguration: PlayerConfiguration

    init(
        _ casinoRepository: CasinoRepository,
        _ playerConfiguration: PlayerConfiguration,
        _ promotionRepository: PromotionRepository)
    {
        self.casinoRepository = casinoRepository
        self.playerConfiguration = playerConfiguration
        super.init(webGameRepository: casinoRepository, promotionRepository: promotionRepository)
    }

    func getCasinoBetTypeTags() -> Single<[CasinoGameTag]> {
        casinoRepository.getTags(cultureCode: playerConfiguration.supportLocale.cultureCode())
            .map { (tags: [CasinoGameTag]) -> [CasinoGameTag] in
                tags.filter { (tag: CasinoGameTag) -> Bool in
                    tag is CasinoGameTag.GameType
                }.sorted { lhs, rhs -> Bool in
                    if lhs.id == 0 || rhs.id == 0 {
                        return true
                    }
                    return lhs.id < rhs.id
                }
            }
    }

    func getLobbies() -> Single<[CasinoLobby]> {
        casinoRepository.getLobby()
    }

    func searchGamesByTag(tags: [ProductDTO.GameTag]) -> Observable<[CasinoGame]> {
        let typeIds = tags.map { tag -> Int32 in
            tag.id
        }
        return casinoRepository.searchCasinoGame(lobbyIds: Set<Int32>(), typeId: Set(typeIds))
    }

    func searchGamesByLobby(lobby: CasinoLobbyType) -> Observable<[CasinoGame]> {
        let lobbyIds = CasinoLobbyType.Companion().convert(type: lobby)
        return casinoRepository.searchCasinoGame(lobbyIds: Set([lobbyIds]), typeId: [])
    }
}
