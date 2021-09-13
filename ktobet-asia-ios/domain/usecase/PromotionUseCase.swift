import Foundation
import SharedBu
import RxSwift

protocol PromotionUseCase {
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], bonusTypes: [BonusType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary>
    func getBonusCoupons() -> Single<[BonusCoupon]>
    func getProductPromotionEvents() -> Single<[PromotionEvent.Product]>
    func getRebatePromotionEvents() -> Single<[PromotionEvent.Rebate]>
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions>
    func requestBonusCoupon(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm>
}

protocol CouponUseCase {
    func useBonusCoupon(bonusCoupon: BonusCoupon) -> Completable
    func useRebateCoupon(bonusCoupon: BonusCoupon.Rebate, autoUse: Bool) -> Completable
}

class PromotionUseCaseImpl: PromotionUseCase, CouponUseCase {
    var promotionRepository : PromotionRepository!
    var playerRepository : PlayerRepository!
    
    init(_ promotionRepository : PromotionRepository, playerRepository : PlayerRepository) {
        self.promotionRepository = promotionRepository
        self.playerRepository = playerRepository
    }
    
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], bonusTypes: [BonusType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary> {
        promotionRepository.searchBonusCoupons(keyword: keyword, from: from, to: to, productTypes: productTypes, bonusTypes: bonusTypes, sortingBy: sortingBy, page: page)
    }
    
    func getBonusCoupons() -> Single<[BonusCoupon]> {
        return promotionRepository.getBonusCoupons().map { [weak self] (coupons: [BonusCoupon]) -> [BonusCoupon] in
            guard let `self` = self else { return coupons }
            return self.filterLevelBonusCoupon(list: coupons)
        }
    }
    
    private func filterLevelBonusCoupon(list: [BonusCoupon]) -> [BonusCoupon] {
        var filterResults = list.filter({ !($0 is BonusCoupon.DepositReturnLevel) })
        var levelCoupon: [BonusCoupon.DepositReturnLevel] = list.filterThenCast()
        levelCoupon = getOneCouponOfEachLevel(all: levelCoupon)
        filterResults.append(contentsOf: levelCoupon)
        return filterResults
    }
    
    private func getOneCouponOfEachLevel(all: [BonusCoupon.DepositReturnLevel]) -> [BonusCoupon.DepositReturnLevel] {
        var eachLevelCoupons: [BonusCoupon.DepositReturnLevel] = []
        all.forEach { (eachCoupon) in
            if let existCoupon = eachLevelCoupons.first(where: { $0.level == eachCoupon.level }) {
                self.keepEarlierCoupon(coupons: &eachLevelCoupons, existCoupon: existCoupon, eachCoupon: eachCoupon)
            } else {
                eachLevelCoupons.append(eachCoupon)
            }
        }
        return eachLevelCoupons
    }
    
    private func keepEarlierCoupon(coupons: inout [BonusCoupon.DepositReturnLevel], existCoupon: BonusCoupon.DepositReturnLevel, eachCoupon: BonusCoupon.DepositReturnLevel) {
        if isItem1AfterItem2(item1: existCoupon, item2: eachCoupon) {
            coupons = coupons.filter({ $0 != existCoupon} )
            coupons.append(eachCoupon)
        }
    }
    
    private func isItem1AfterItem2(item1: BonusCoupon.DepositReturnLevel, item2: BonusCoupon.DepositReturnLevel) -> Bool {
        let period1 = item1.validPeriod
        let period2 = item2.validPeriod
        switch period1 {
        case let period1 as ValidPeriod.Duration:
            switch period2 {
            case let period2 as ValidPeriod.Duration:
                let date1 = period1.start.localDateTime.convertToDate()
                let date2 = period2.end.localDateTime.convertToDate()
                return date1 > date2
            case is ValidPeriod.Always:
                return false
            default:
                return false
            }
        case is ValidPeriod.Always:
            return true
        default:
            return true
        }
    }
    
    func getProductPromotionEvents() -> Single<[PromotionEvent.Product]> {
        return self.promotionRepository.getProductPromotions()
    }
    
    func getRebatePromotionEvents() -> Single<[PromotionEvent.Rebate]> {
        return self.promotionRepository.getRebatePromotions()
    }
    
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions> {
        return self.promotionRepository.getPromotionDetail(promotionId: promotionId)
    }
    
    func useBonusCoupon(bonusCoupon: BonusCoupon) -> Completable {
        return self.promotionRepository.useCoupon(bonusCoupon: bonusCoupon, autoUse: false)
    }
    func useRebateCoupon(bonusCoupon: BonusCoupon.Rebate, autoUse: Bool) -> Completable {
        return self.promotionRepository.useCoupon(bonusCoupon: bonusCoupon, autoUse: autoUse)
    }
    
    func requestBonusCoupon(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
        switch bonusCoupon {
        case is BonusCoupon.Product,
             is BonusCoupon.FreeBet,
             is BonusCoupon.DepositReturn:
            return confirmUseBonusCoupon(bonusCoupon)
        case let rebate as BonusCoupon.Rebate:
            return confirmUseRebateCoupon(rebate)
        default:
            return Single.just(DoNothing())
        }
    }
    
    private func confirmUseBonusCoupon(_ bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
        return verifyDepositReturnCouponLimitation(bonusCoupon)
            .andThen(verifyAccountLockedBonus(bonusCoupon))
            .andThen(Single.just(ConfirmUseBonusCoupon(useCase: self, bonusCoupon: bonusCoupon)))
            .catchError({ (error) -> Single<WaitingConfirm> in
                if let exception = error as? PromotionException {
                    var waitingConfirm: WaitingConfirm
                    switch exception {
                    case is PromotionException.DepositCouponFullException:
                        waitingConfirm = ConfirmUsageFull()
                    case let e as PromotionException.DepositBonusHasTurnOverException:
                        waitingConfirm = ConfirmUseWithTurnOver(hint: e.hint, useCase: self, bonusCoupon: bonusCoupon)
                    case is PromotionException.LockedBonusCalculatingException:
                        waitingConfirm = ConfirmLockedBonusCalculating()
                    case let e as PromotionException.HasLockedBonusHintException:
                        waitingConfirm = ConfirmLockedBonusHintForNoTurnOverCoupon(useCase: self, turnOver: e.turnOver, bonusCoupon: bonusCoupon)
                    case let e as PromotionException.BlockedByLockedBonus:
                        waitingConfirm = ConfirmBonusLocked(turnOver: e.turnOver)
                    default:
                        return Single.error(error)
                    }
                    return Single.just(waitingConfirm)
                }
                return Single.error(error)
            })
    }
    
    private func verifyDepositReturnCouponLimitation(_ bonusCoupon: BonusCoupon) -> Completable {
        if let coupon = bonusCoupon as? BonusCoupon.DepositReturn, coupon.isFull() {
            return Completable.error(PromotionException.DepositCouponFullException())
        } else {
            return Completable.empty()
        }
    }
    
    private func verifyAccountLockedBonus(_ bonusCoupon: BonusCoupon) -> Completable {
        return self.promotionRepository.hasAccountLockedBonus().flatMapCompletable({ [unowned self] (hasLockedBonus) in
            if hasLockedBonus && bonusCoupon.hasTurnOver() {
                return self.checkLockedBonusStatus().andThen(self.promotionRepository.getLockedBonusDetail()).flatMapCompletable({
                    return Completable.error(PromotionException.BlockedByLockedBonus(turnOver: $0))
                })
            } else if hasLockedBonus && !bonusCoupon.hasTurnOver() {
                return self.checkLockedBonusStatus().andThen(self.promotionRepository.getLockedBonusDetail()).flatMapCompletable({
                    return Completable.error(PromotionException.HasLockedBonusHintException(turnOver: $0))
                })
            } else if !hasLockedBonus && bonusCoupon.hasTurnOver() {
                return self.promotionRepository.getTurnOverDetail(bonusCoupon: bonusCoupon).flatMapCompletable({
                    return Completable.error(PromotionException.DepositBonusHasTurnOverException(hint: $0))
                })
            } else {
                return Completable.empty()
            }
        })
    }
    
    private func checkLockedBonusStatus() -> Completable {
        return self.promotionRepository.isLockedBonusCalculating().flatMapCompletable({ (calculating) in
            if calculating {
                return Completable.error(PromotionException.LockedBonusCalculatingException())
            } else {
                return Completable.empty()
            }
        })
    }
    
    private func confirmUseRebateCoupon(_ bonusCoupon: BonusCoupon.Rebate) -> Single<WaitingConfirm> {
        return verifyAccountLockedBonus(bonusCoupon)
            .andThen(Single.just(ConfirmAutoUse(useCase: self, bonusCoupon: bonusCoupon)))
            .catchError({ (error) -> Single<WaitingConfirm> in
                if let exception = error as? PromotionException {
                    var waitingConfirm: WaitingConfirm
                    switch exception {
                    case is PromotionException.LockedBonusCalculatingException:
                        waitingConfirm = ConfirmLockedBonusCalculating()
                    case let e as PromotionException.HasLockedBonusHintException:
                        waitingConfirm = ConfirmLockedBonusHintForRebateCoupon(useCase: self, turnOver: e.turnOver, bonusCoupon: bonusCoupon)
                    default:
                        return Single.error(error)
                    }
                    return Single.just(waitingConfirm)
                }
                return Single.error(error)
            })
    }
}
