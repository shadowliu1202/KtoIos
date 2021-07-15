import Foundation
import SharedBu
import RxSwift

protocol P2PUseCase {
    func getTurnOverStatus() -> Single<P2PTurnOver>
    func getAllGames() -> Single<[P2PGame]>
    func createGame(gameId: Int32) -> Single<URL?>
}

class P2PUseCaseImpl: P2PUseCase {
    
    var p2pRepository : P2PRepository!
    
    init(_ p2pRepository : P2PRepository) {
        self.p2pRepository = p2pRepository
    }
    
    func getTurnOverStatus() -> Single<P2PTurnOver> {
        p2pRepository.getTurnOverStatus()
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        p2pRepository.getAllGames()
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        p2pRepository.createGame(gameId: gameId)
    }
}
