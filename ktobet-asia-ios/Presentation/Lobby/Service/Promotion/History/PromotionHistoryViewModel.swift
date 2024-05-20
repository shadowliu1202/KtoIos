import Foundation
import RxCocoa
import RxSwift
import sharedbu

class PromotionHistoryViewModel: CollectErrorViewModel {
    private let promotionUseCase: PromotionUseCase
    private let playerConfiguration: PlayerConfiguration

    private let totalCountAmountRelay = BehaviorRelay(value: "")

    private let disposeBag = DisposeBag()

    private var recordPagination: Pagination<CouponHistory>!

    private(set) var keywordRelay: BehaviorRelay<String?> = .init(value: nil)

    var sortingBy: SortingType = .desc
    var productTypes: [ProductType] = []
    var privilegeTypes: [PrivilegeType] = [
        .freebet,
        .depositBonus,
        .rebate,
        .levelBonus,
        .product,
        .vvipcashBack
    ]

    var beginDate = Date().getPastSevenDate()
    var endDate = Date()

    var totalCountAmountDriver: Driver<String> {
        totalCountAmountRelay.asDriver()
    }

    var historiesDriver: Driver<[CouponHistory]> {
        recordPagination.elements.skip(1).asDriverOnErrorJustComplete()
    }

    init(
        _ promotionUseCase: PromotionUseCase,
        _ playerConfiguration: PlayerConfiguration)
    {
        self.promotionUseCase = promotionUseCase
        self.playerConfiguration = playerConfiguration

        super.init()

        self.recordPagination = Pagination<CouponHistory>(
            startIndex: 1,
            offset: 1,
            observable: { [weak self] page -> Observable<[CouponHistory]> in
                guard let self else { return .just([]) }
                return self.searchBonusCoupons(page: page)
            })

        keywordRelay
            .compactMap { $0 }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchData()
            })
            .disposed(by: disposeBag)
    }

    func searchBonusCoupons(page: Int) -> Observable<[CouponHistory]> {
        promotionUseCase
            .searchBonusCoupons(
                keyword: keywordRelay.value ?? "",
                from: beginDate,
                to: endDate,
                productTypes: productTypes,
                privilegeTypes: privilegeTypes,
                sortingBy: sortingBy,
                page: page)
            .do(onSuccess: { [weak self] in
                self?.totalCountAmountRelay.accept(
                    Localize.string("bonus_promotioncount", ["\($0.totalCoupon)", $0.summary.description()]))
            }, onError: { [weak self] in
                self?.errorsSubject.onNext($0)
            })
            .map { $0.couponHistory }
            .asObservable()
    }

    func fetchData() {
        recordPagination.refreshTrigger.onNext(())
    }

    func fetchNextPage() {
        recordPagination.loadNextPageTrigger.onNext(())
    }
  
    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }
}
