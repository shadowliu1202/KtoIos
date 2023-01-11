import Foundation
import SharedBu
import RxSwift

protocol ArcadeUseCase: WebGameUseCase {
    func getGames(isRecommend: Bool, isNew: Bool) -> Observable<[ArcadeGame]>
}

class ArcadeUseCaseImpl: WebGameUseCaseImpl, ArcadeUseCase {
    private let arcadeRepository : ArcadeRepository
    
    init(arcadeRepository : ArcadeRepository, promotionRepository: PromotionRepository) {
        self.arcadeRepository = arcadeRepository
        super.init(webGameRepository: arcadeRepository, promotionRepository: promotionRepository)
    }
    
    func getGames(isRecommend: Bool, isNew: Bool) -> Observable<[ArcadeGame]> {
        return arcadeRepository.searchGames(isRecommend: isRecommend, isNew: isNew)
    }
}
