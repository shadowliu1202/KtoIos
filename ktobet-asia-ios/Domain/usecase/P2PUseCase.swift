import Foundation
import RxSwift
import sharedbu

protocol P2PUseCase: WebGameCreateUseCase {
    func getTurnOverStatus() -> Single<P2PTurnOver>
    func getAllGames() -> Single<[P2PGame]>
}

class P2PUseCaseImpl: P2PUseCase {
    let p2pRepository: P2PRepository
    let promotionRepository: PromotionRepository

    var webGameCreateRepository: WebGameCreateRepository { p2pRepository }

    init(
        p2pRepository: P2PRepository,
        promotionRepository: PromotionRepository)
    {
        self.p2pRepository = p2pRepository
        self.promotionRepository = promotionRepository
    }

    func getTurnOverStatus() -> Single<P2PTurnOver> {
        p2pRepository.getTurnOverStatus()
    }

    func getAllGames() -> Single<[P2PGame]> {
        p2pRepository.getAllGames()
    }
}
