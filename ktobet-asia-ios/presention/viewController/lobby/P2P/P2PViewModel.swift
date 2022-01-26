import Foundation
import RxSwift
import RxCocoa
import SharedBu


class P2PViewModel {
    private var p2pUseCase: P2PUseCase!
    private var productName: String! = "p2p"
    
    init(p2pUseCase: P2PUseCase) {
        self.p2pUseCase = p2pUseCase
    }
    
    func getTurnOverStatus() -> Single<P2PTurnOver> {
        p2pUseCase.getTurnOverStatus()
    }
    
    func getAllGames() -> Single<[P2PGame]> {
        p2pUseCase.getAllGames().do(onSuccess:{ self.productName = $0.first?.productName })
    }
}

extension P2PViewModel: ProductWebGameViewModelProtocol {
    func getGameProduct() -> String {
        return productName
    }
    
    func getGameProductType() -> ProductType {
        ProductType.p2p
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        p2pUseCase.createGame(gameId: gameId)
    }
}
