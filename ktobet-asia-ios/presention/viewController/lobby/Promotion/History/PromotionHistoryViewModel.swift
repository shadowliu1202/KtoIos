import Foundation
import RxSwift
import RxCocoa
import SharedBu


class PromotionHistoryViewModel {
    private let promotionUseCase: PromotionUseCase
    
    var recordPagination: Pagination<CouponHistory>!
    
    var keyword: String = ""
    var sortingBy: SortingType = .desc
    var productTypes: [ProductType] = []
    var privilegeTypes: [PrivilegeType] = [.freebet, .depositbonus, .rebate, .levelbonus, .product, .vvipcashback]
    var beginDate = Date().getPastSevenDate()
    var endDate = Date()
    var relayTotalCountAmount = BehaviorRelay(value: "")
    
    init(promotionUseCase: PromotionUseCase) {
        self.promotionUseCase = promotionUseCase
        self.recordPagination = Pagination<CouponHistory>(
            pageIndex: 1,
            offset: 1,
            observable: { [weak self] page -> Observable<[CouponHistory]> in
                self?.searchBonusCoupons(page: page)
                    .do(onError: { error in
                        self?.recordPagination.error.onNext(error)
                    })
                    .catch( { error -> Observable<[CouponHistory]> in
                        Observable.empty()
                    }) ?? .just([])
            }
        )
    }
    
    func searchBonusCoupons(page: Int) -> Observable<[CouponHistory]> {
        promotionUseCase
            .searchBonusCoupons(
                keyword: keyword,
                from: beginDate,
                to: endDate,
                productTypes: productTypes,
                privilegeTypes: privilegeTypes,
                sortingBy: sortingBy,
                page: page
            )
            .do(onSuccess: { [weak self] in
                self?.relayTotalCountAmount.accept(
                    String(format: Localize.string("bonus_promotioncount"), "\($0.totalCoupon)", $0.summary.description())
                )
            })
            .map{ $0.couponHistory }
            .asObservable()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
