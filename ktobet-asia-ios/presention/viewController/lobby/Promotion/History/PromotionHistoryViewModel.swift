import Foundation
import RxSwift
import RxCocoa
import SharedBu


class PromotionHistoryViewModel {
    private var promotionUseCase: PromotionUseCase!
    
    var recordPagination: Pagination<CouponHistory>!
    var keyword: String = ""
    var sortingBy: SortingType = .desc
    var productTypes: [ProductType] = []
    var bonusTypes: [BonusType] = [BonusType.freebet, BonusType.depositbonus, BonusType.rebate, BonusType.levelbonus, BonusType.product]
    var beginDate: Date = Date().getPastSevenDate()
    var endDate: Date = Date()
    var relayTotalCountAmount = BehaviorRelay(value: "")
    
    init(promotionUseCase: PromotionUseCase) {
        self.promotionUseCase = promotionUseCase
        recordPagination = Pagination<CouponHistory>(pageIndex: 1, offset: 1, callBack: {(page) -> Observable<[CouponHistory]> in
            self.searchBonusCoupons(page: page)
                .do(onError: { error in
                    self.recordPagination.error.onNext(error)
                }).catchError( { error -> Observable<[CouponHistory]> in
                    Observable.empty()
                })
        })
    }
    
    func searchBonusCoupons(page: Int) -> Observable<[CouponHistory]> {
        promotionUseCase.searchBonusCoupons(keyword: keyword, from: beginDate, to: endDate, productTypes: productTypes, bonusTypes: bonusTypes, sortingBy: sortingBy, page: page).do(onSuccess: {
            self.relayTotalCountAmount.accept(String(format: Localize.string("bonus_promotioncount"), "\($0.totalCoupon)", $0.summary.description()))
        }).map{ $0.couponHistory }.asObservable()
    }
}
