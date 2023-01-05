import Foundation
import SharedBu
import RxSwift
import RxCocoa

enum WebGameBonusStatus {
    case normal(WebGameWithProperties?)
    case bonusCalculating(gameName: String)
    case lockedBonus(gameName: String, TurnOverDetail)
}

protocol WebGameCheckBonusUseCase {
    var clickGameTrigger: PublishSubject<WebGameWithProperties> { get }
    var allowGoWebGameDriver: Driver<WebGameBonusStatus?> { get }
    
    func subscribeGameClick(onError: ((Error) -> Void)?, disposed bag: DisposeBag)
}

class WebGameCheckBonusUseCaseImpl: WebGameCheckBonusUseCase {
    private let allowGoWebGameSubject = PublishSubject<WebGameBonusStatus?>()
    private let promotionRepository: PromotionRepository
    
    let clickGameTrigger = PublishSubject<WebGameWithProperties>()
    
    var allowGoWebGameDriver: Driver<WebGameBonusStatus?> {
        allowGoWebGameSubject.asDriverLogError()
    }
    
    init(promotionRepository: PromotionRepository) {
        self.promotionRepository = promotionRepository
    }
    
    func subscribeGameClick(
        onError: ((Error) -> Void)?,
        disposed bag: DisposeBag
    ) {
        clickGameTrigger
            .flatMapLatest { [unowned self] in
                self.handleGame($0).materialize()
            }
            .subscribe(onNext: { [weak self] in
                switch $0 {
                case .next(let status):
                    self?.allowGoWebGameSubject.onNext(status)
                case .error(let error):
                    onError?(error)
                default:
                    break
                }
            })
            .disposed(by: bag)
    }
    
    private func handleGame(_ game: WebGameWithProperties) -> Observable<WebGameBonusStatus> {
        guard game.isActive
        else {
            return .just(.normal(nil))
        }
                
        if game.requireNoBonusLock {
            return isBonusLockOrCalculating(game)
        }
        else {
            return .just(.normal(game))
        }
    }
    
    private func isBonusLockOrCalculating(_ game: WebGameWithProperties) -> Observable<WebGameBonusStatus> {
        let bonusDetail = promotionRepository
            .getLockedBonusDetail()
            .asObservable()
            .map {
                WebGameBonusStatus.lockedBonus(gameName: game.gameName, $0)
            }
        
        let checkBonus = promotionRepository
            .isLockedBonusCalculating()
            .asObservable()
            .flatMap {
                if $0 {
                    return Observable.just(WebGameBonusStatus.bonusCalculating(gameName: game.gameName))
                }
                else {
                    return bonusDetail
                }
            }
        
        return promotionRepository
            .hasAccountLockedBonus()
            .asObservable()
            .flatMap { locked in
                if locked {
                    return checkBonus
                }
                else {
                    return .just(.normal(game))
                }
            }
    }
}
