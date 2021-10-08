import Foundation
import RxSwift
import SharedBu

protocol PromotionRepository {
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], bonusTypes: [BonusType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary>
    func getBonusCoupons() -> Single<[BonusCoupon]>
    func getProductPromotions() -> Single<[PromotionEvent.Product]>
    func getRebatePromotions() -> Single<[PromotionEvent.Rebate]>
    func hasAccountLockedBonus() -> Single<Bool>
    func isLockedBonusCalculating() -> Single<Bool>
    func getLockedBonusDetail() -> Single<TurnOverDetail>
    func getTurnOverDetail(bonusCoupon: BonusCoupon) -> Single<TurnOverHint>
    func useCoupon(bonusCoupon: BonusCoupon, autoUse: Bool) -> Completable
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions>
}


class PromotionRepositoryImpl: PromotionRepository {
    private var promotionApi: PromotionApi!
    
    init(_ promotionApi: PromotionApi) {
        self.promotionApi = promotionApi
    }
    
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], bonusTypes: [BonusType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary> {
        let request = PromotionHistoryRequest(begin: from.toDateString(with: "-"),
                                              end: to.toDateString(with: "-"),
                                              page: page,
                                              productType: productTypes.map{ ProductType.convert($0) },
                                              query: keyword,
                                              selected: sortingBy.rawValue,
                                              type: bonusTypes.map{ BonusType.convert($0) })
        return promotionApi.searchPromotionHistory(request: request).map{ (response) -> CouponHistorySummary in
            guard let data = response.data else { return CouponHistorySummary(summary: CashAmount(amount: 0), totalCoupon: 0, couponHistory: [])}
            return data.convertToPromotions()
        }
    }
    
    func getBonusCoupons() -> Single<[BonusCoupon]> {
        return self.promotionApi.getBonusCoupons().map({ (response) in
            guard let data = response.data else { return [] }
            return data.map({ $0.toBonusCoupon() })
        })
    }
    
    func getProductPromotions() -> Single<[PromotionEvent.Product]> {
        return self.promotionApi.getProductPromotions().map { (response) in
            guard let data = response.data else { return [] }
            return data.map({ $0.toProductPromotion() })
        }
    }
    
    func getRebatePromotions() -> Single<[PromotionEvent.Rebate]> {
        return self.promotionApi.getPromotions().map { (response) in
            guard let data = response.data else { return [] }
            return data.map({ $0.toRebatePromotion() })
        }
    }
    
    func hasAccountLockedBonus() -> Single<Bool> {
        return self.promotionApi.getLockedBonus().map { (response) in
            guard let data = response.data else { return false }
            if let status = data.status, status == .Used {
                return true
            } else {
                return false
            }
        }
    }
    
    func isLockedBonusCalculating() -> Single<Bool> {
        return self.promotionApi.checkBonusTag().map({ (response) in
            return !(response.data?.hasBonusTag ?? false)
        })
    }
    
    func getLockedBonusDetail() -> Single<TurnOverDetail> {
        return self.promotionApi.getCurrentLockedBonus().flatMap({ (response) in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single<TurnOverDetail>.just(data.toTurnOverDetail())
        })
    }
    
    func getTurnOverDetail(bonusCoupon: BonusCoupon) -> Single<TurnOverHint> {
        return self.promotionApi.getCouponTurnOverDetail(bonusId: bonusCoupon.bonusId).flatMap { (response) in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single<TurnOverHint>.just(data.toTurnOverHint())
        }
    }
    
    func useCoupon(bonusCoupon: BonusCoupon, autoUse: Bool) -> Completable {
        let request = BonusRequest(autoUse: autoUse, no: bonusCoupon.bonusId, type: BonusType.convert(bonusCoupon.bonusType))
        return self.promotionApi.useBonusCoupon(bonus: request).asCompletable()
    }
    
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions> {
        return self.promotionApi.getBonusContentTemplate(displayId: promotionId).flatMap { (response) in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single<PromotionDescriptions>.just(data.toPromotionDescriptions())
        }
    }
}

struct CouponHistorySummary {
    var summary: CashAmount
    var totalCoupon: Int
    var couponHistory: [CouponHistory]
}
