import Foundation
import RxSwift
import SharedBu

protocol PromotionRepository {
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], privilegeTypes: [PrivilegeType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary>
    func getBonusCoupons() -> Single<[BonusCoupon]>
    func getProductPromotions() -> Single<[PromotionEvent.Product]>
    func getRebatePromotions() -> Single<[PromotionEvent.Rebate]>
    func getCashbackPromotions() -> Single<[PromotionEvent.VVIPCashback]>
    func hasAccountLockedBonus() -> Single<Bool>
    func isLockedBonusCalculating() -> Single<Bool>
    func getLockedBonusDetail() -> Single<TurnOverDetail>
    func getTurnOverDetail(bonusCoupon: BonusCoupon) -> Single<TurnOverHint>
    func useCoupon(bonusCoupon: BonusCoupon, autoUse: Bool) -> Completable
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions>
    func getCashBackSettings(displayId: String) -> Single<[CashBackSetting]>
}


class PromotionRepositoryImpl: PromotionRepository {
    private var promotionApi: PromotionApi!
    
    init(_ promotionApi: PromotionApi) {
        self.promotionApi = promotionApi
    }
    
    func searchBonusCoupons(keyword: String, from: Date, to: Date, productTypes: [ProductType], privilegeTypes: [PrivilegeType], sortingBy: SortingType, page: Int) -> Single<CouponHistorySummary> {
        let request = PromotionHistoryRequest(begin: from.toDateString(with: "-"),
                                              end: to.toDateString(with: "-"),
                                              page: page,
                                              productType: productTypes.map{ ProductType.convert($0) },
                                              query: keyword,
                                              selected: sortingBy.rawValue,
                                              type: privilegeTypes.map{ PrivilegeType.convert($0) })
        return promotionApi.searchPromotionHistory(request: request).map{ (response) -> CouponHistorySummary in
            guard let data = response.data else { return CouponHistorySummary(summary: 0.toAccountCurrency(), totalCoupon: 0, couponHistory: [])}
            return try data.convertToPromotions()
        }
    }
    
    func getBonusCoupons() -> Single<[BonusCoupon]> {
        return self.promotionApi.getBonusCoupons().map({ (response) in
            guard let data = response.data else { return [] }
            return try data.map({ try $0.toBonusCoupon() })
        })
    }
    
    func getProductPromotions() -> Single<[PromotionEvent.Product]> {
        return self.promotionApi.getProductPromotions().map { (response) in
            guard let data = response.data else { return [] }
            return try data.map({ try $0.toProductPromotion() })
        }
    }
    
    func getRebatePromotions() -> Single<[PromotionEvent.Rebate]> {
        return self.promotionApi.getPromotions().map { (response) in
            guard let data = response.data else { return [] }
            return try data.map({ try $0.toRebatePromotion() })
        }
    }
    
    func getCashbackPromotions() -> Single<[PromotionEvent.VVIPCashback]> {
        self.promotionApi.getCashbackPromotions().map { (response) in
            guard let data = response.data else { return [] }
            return try data.map({ try $0.toCashbackPromotion() })
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
            return Single<TurnOverDetail>.just(try data.toTurnOverDetail())
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
    
    func getCashBackSettings(displayId: String) -> Single<[CashBackSetting]> {
        promotionApi.getCashBackSettings(displayId: displayId)
            .map ({ responseDataList in
                responseDataList.data
                    .map ({ bean in
                        CashBackSetting(
                            cashBackPercentage: Percentage(percent: Double(bean.cashBackPercentage.replacingOccurrences(of: "%", with: "")) ?? 0),
                            lossAmountRange: bean.lossAmountRange,
                            maxAmount: bean.maxAmount.toAccountCurrency())
                    })
            })
    }
}

struct CouponHistorySummary {
    var summary: AccountCurrency
    var totalCoupon: Int
    var couponHistory: [CouponHistory]
}
