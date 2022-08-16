import Foundation
import SharedBu
import RxSwift

protocol ArcadeUseCase: WebGameUseCase {
    func getGames(isRecommend: Bool, isNew: Bool) -> Observable<[ArcadeGame]>
}

class ArcadeUseCaseImpl: WebGameUseCaseImpl, ArcadeUseCase {
    var arcadeRepository : ArcadeRepository!
    
    init(_ arcadeRepository : ArcadeRepository) {
        super.init(arcadeRepository)
        self.arcadeRepository = arcadeRepository
    }
    
    func getGames(isRecommend: Bool, isNew: Bool) -> Observable<[ArcadeGame]> {
        return arcadeRepository.searchGames(isRecommend: isRecommend, isNew: isNew)
    }
}
