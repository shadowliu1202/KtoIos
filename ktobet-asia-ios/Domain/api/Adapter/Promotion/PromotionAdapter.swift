import Foundation
import sharedbu

class PromotionAdapter: PromotionProtocol {
    func getCurrentTurnover() -> SingleWrapper<ResponseItem<TurnoverBean>> {
        fatalError()
    }
  
    func getLockedBonus() -> SingleWrapper<ResponseItem<LockedBonusBean>> {
        fatalError()
    }
  
    func hasTurnover() -> SingleWrapper<ResponseItem<HasTurnoverBean>> {
        fatalError()
    }
}
