import Foundation
import SharedBu
import RxSwift

protocol ArcadeUseCase: WebGameUseCase {
    func getGames(tags: [GameFilter]) -> Observable<[ArcadeGame]>
}

class ArcadeUseCaseImpl: WebGameUseCaseImpl, ArcadeUseCase {
    var arcadeRepository : ArcadeRepository!
    
    init(_ arcadeRepository : ArcadeRepository) {
        super.init(arcadeRepository)
        self.arcadeRepository = arcadeRepository
    }
    
    func getGames(tags: [GameFilter]) -> Observable<[ArcadeGame]> {
        return arcadeRepository.searchGames(tags: tags)
    }
}
