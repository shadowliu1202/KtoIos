import Foundation
import RxSwift
import sharedbu

protocol PromotionRepository {
    func searchBonusCoupons(
        keyword: String,
        from: Date,
        to: Date,
        productTypes: [ProductType],
        privilegeTypes: [PrivilegeType],
        sortingBy: SortingType,
        page: Int) -> Single<CouponHistorySummary>

    func getCouponsAndPromotions() -> Single<BonusBean>
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
    private let promotionApi: PromotionApi
    private lazy var couponsAndPromotions = getCouponsAndPromotions()
        .asObservable()
        .share()

    init(_ promotionApi: PromotionApi) {
        self.promotionApi = promotionApi
    }

    func searchBonusCoupons(
        keyword: String,
        from: Date,
        to: Date,
        productTypes: [ProductType],
        privilegeTypes: [PrivilegeType],
        sortingBy: SortingType,
        page: Int)
        -> Single<CouponHistorySummary>
    {
        let request = PromotionHistoryRequest(
            begin: from.toDateString(with: "-"),
            end: to.toDateString(with: "-"),
            page: page,
            productType: productTypes.map { ProductType.convert($0) },
            query: keyword,
            selected: sortingBy.rawValue,
            type: privilegeTypes.map { PrivilegeType.convert($0) })
        return promotionApi.searchPromotionHistory(request: request).map { response -> CouponHistorySummary in
            guard let data = response.data
            else { return CouponHistorySummary(summary: 0.toAccountCurrency(), totalCoupon: 0, couponHistory: []) }
            return try data.convertToPromotions()
        }
    }

    func getCouponsAndPromotions() -> Single<BonusBean> {
        promotionApi
            .getBonusCoupons()
            .map {
                guard let data = $0.data else { throw KTOError.WrongDateFormat }
                return data
            }
    }

    func getBonusCoupons() -> Single<[BonusCoupon]> {
        couponsAndPromotions
            .map { bonus in
                bonus.coupons
                    .compactMap { try? $0.toBonusCoupon() }
            }
            .asSingle()
    }

    func getProductPromotions() -> Single<[PromotionEvent.Product]> {
        couponsAndPromotions
            .map { bonus in
                bonus.productPromotions
                    .compactMap { try? $0.toProductPromotion() }
            }
            .asSingle()
    }

    func getRebatePromotions() -> Single<[PromotionEvent.Rebate]> {
        couponsAndPromotions
            .map { bonus in
                bonus.rebatePromotions
                    .compactMap { try? $0.toRebatePromotion() }
            }
            .asSingle()
    }

    func getCashbackPromotions() -> Single<[PromotionEvent.VVIPCashback]> {
        couponsAndPromotions
            .map { bonus in
                bonus.cashbackPromotions
                    .compactMap { try? $0.toCashbackPromotion() }
            }
            .asSingle()
    }

    func hasAccountLockedBonus() -> Single<Bool> {
        self.promotionApi.getLockedBonus().map { response in
            guard let data = response.data else { return false }
            if let status = data.status, status == .Used {
                return true
            }
            else {
                return false
            }
        }
    }

    func isLockedBonusCalculating() -> Single<Bool> {
        self.promotionApi.checkBonusTag().map({ response in
            !(response.data?.hasBonusTag ?? false)
        })
    }

    func getLockedBonusDetail() -> Single<TurnOverDetail> {
        self.promotionApi.getCurrentLockedBonus().flatMap({ response in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return try Single<TurnOverDetail>.just(data.toTurnOverDetail())
        })
    }

    func getTurnOverDetail(bonusCoupon: BonusCoupon) -> Single<TurnOverHint> {
        self.promotionApi.getCouponTurnOverDetail(bonusId: bonusCoupon.bonusId).flatMap { response in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single<TurnOverHint>.just(data.toTurnOverHint())
        }
    }

    func useCoupon(bonusCoupon: BonusCoupon, autoUse: Bool) -> Completable {
        let request = BonusRequest(autoUse: autoUse, no: bonusCoupon.bonusId, type: BonusType.convert(bonusCoupon.bonusType))
        return self.promotionApi.useBonusCoupon(bonus: request).asCompletable()
    }

    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions> {
        self.promotionApi.getBonusContentTemplate(displayId: promotionId).flatMap { response in
            guard let data = response.data else { return Single.error(KTOError.EmptyData) }
            return Single<PromotionDescriptions>.just(data.toPromotionDescriptions())
        }
    }

    func getCashBackSettings(displayId: String) -> Single<[CashBackSetting]> {
        promotionApi.getCashBackSettings(displayId: displayId)
            .map({ responseDataList in
                responseDataList.data
                    .map({ bean in
                        CashBackSetting(
                            cashBackPercentage: Percentage(percent: Double(
                                bean.cashBackPercentage
                                    .replacingOccurrences(of: "%", with: "")) ?? 0),
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
