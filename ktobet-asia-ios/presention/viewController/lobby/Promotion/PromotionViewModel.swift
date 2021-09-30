import Foundation
import RxSwift
import RxCocoa
import SharedBu

class PromotionViewModel {
    private var promotionUseCase: PromotionUseCase!
    private var playerUseCase : PlayerDataUseCase!
    
    private lazy var bonusCoupons = self.promotionUseCase.getBonusCoupons().asObservable()
    private lazy var productPromotions = self.promotionUseCase.getProductPromotionEvents().asObservable()
    private lazy var rebatePromotions = self.promotionUseCase.getRebatePromotionEvents().asObservable()
    
    private lazy var trigerRefresh = BehaviorRelay<Void>(value: ())
    private lazy var freeBetCoupon: Observable<[BonusCoupon.FreeBet]> = self.bonusCoupons.map { $0.filterThenCast() }
    private lazy var depositReturnCoupon: Observable<[BonusCoupon.DepositReturn]> = self.bonusCoupons.map { $0.filterThenCast() }
    private lazy var productOfBonusCoupon: Observable<[BonusCoupon.Product]> = self.bonusCoupons.map { $0.filterThenCast() }
    private lazy var productPromotionSummary: Observable<([BonusCoupon.Product], [PromotionEvent.Product])> = Observable.combineLatest(productOfBonusCoupon, productPromotions)
    private lazy var rebateOfBonusCoupon: Observable<[BonusCoupon.Rebate]> = self.bonusCoupons.map { $0.filterThenCast() }
    private lazy var rebatePromotionSummary: Observable<([BonusCoupon.Rebate], [PromotionEvent.Rebate])> = Observable.combineLatest(rebateOfBonusCoupon, rebatePromotions).map { (coupon, rebate) -> ([BonusCoupon.Rebate], [PromotionEvent.Rebate]) in
        if rebate.contains(where: {$0.isAutoUse}) {
            return ([], rebate)
        }
        return (coupon, rebate)
    }
    
    private var filterOfSorce = BehaviorRelay<PromotionFilter>(value: .all)
    private(set) var sectionHeaders: [String] = []
    lazy var dataSource = Observable.combineLatest(trigerRefresh, filterOfSorce).flatMap { [unowned self] (_, selected) -> Observable<[[PromotionVmItem]]> in
        switch selected {
        case .all:
            self.sectionHeaders = [Localize.string("bonus_bonustype_manual"), Localize.string("bonus_bonustype_1"), Localize.string("bonus_bonustype_2"), Localize.string("bonus_bonustype_3"), Localize.string("bonus_bonustype_4")]
            return Observable.combineLatest(self.manualCoupon, self.freeBets, self.depositReturns, self.products, self.rebates).map({[$0,$1,$2,$3,$4]})
        case .manual:
            self.sectionHeaders.removeAll()
            return self.manualCoupon.map({[$0]})
        case .freeBet:
            self.sectionHeaders.removeAll()
            return self.freeBets.map({[$0]})
        case .depositReturn:
            self.sectionHeaders.removeAll()
            return self.depositReturns.map({[$0]})
        case .product:
            self.sectionHeaders.removeAll()
            return self.productsWithFilter.map({[$0]})
        case .rebate:
            self.sectionHeaders.removeAll()
            return self.rebates.map({[$0]})
        }
    }
    lazy var filterSource = trigerRefresh.flatMap({
        return Observable.combineLatest(self.manualCoupon, self.freeBets, self.depositReturns, self.products, self.rebates).map({ [unowned self] (manualCoupons, freebets, depositReturns, products, rebates) -> [(PromotionFilter, Int)] in
            let allCount = manualCoupons.count + freebets.count + depositReturns.count + products.count + rebates.count
            return [(.all, allCount), (.manual, manualCoupons.count), (.freeBet, freebets.count), (.depositReturn, depositReturns.count), (.product, products.count), (.rebate, rebates.count)]
        })
    })
    lazy var freeBets: Observable<[PromotionVmItem]> = self.freeBetCoupon.map({ $0.mapToItem() })
    lazy var depositReturns: Observable<[PromotionVmItem]> = self.depositReturnCoupon.map({ $0.mapToItem() })
    private var filterOfProduct = BehaviorRelay<[PromotionFilter.Product]>(value: [.Sport, .Slot, .Casino, .Numbergame])
    
    lazy var productsWithFilter = Observable.combineLatest(filterOfProduct, self.productPromotionSummary).flatMapLatest({ (filters, summary) -> Observable<[PromotionVmItem]> in
        let (bonusProducts, promotionProducts) = summary
        var bonus: [BonusCoupon.Product] = []
        var promotions: [PromotionEvent.Product] = []
        var filterTypes = filters.map({ self.transfer($0) })
        bonusProducts.forEach({ (product) in
            if filterTypes.contains(product.productType) {
                bonus.append(product)
            }
        })
        promotionProducts.forEach({ (product) in
            if filterTypes.contains(product.type) {
                promotions.append(product)
            }
        })
        var result: [PromotionVmItem] = []
        result.append(contentsOf: bonus.mapToItem())
        result.append(contentsOf: promotions.mapToItem())
        return Observable<[PromotionVmItem]>.just(result)
    })
        
    lazy var products: Observable<[PromotionVmItem]> = self.productPromotionSummary.flatMapLatest { (bonusProducts, promotionProducts) -> Observable<[PromotionVmItem]> in
        var result: [PromotionVmItem] = []
        result.append(contentsOf: bonusProducts.mapToItem())
        result.append(contentsOf: promotionProducts.mapToItem())
        return Observable<[PromotionVmItem]>.just(result)
    }
    lazy var rebates: Observable<[PromotionVmItem]> = self.rebatePromotionSummary.flatMapLatest { (bonusRebates, promotionRebates) -> Observable<[PromotionVmItem]> in
        var result: [PromotionVmItem] = []
        result.append(contentsOf: bonusRebates.mapToItem())
        result.append(contentsOf: promotionRebates.mapToItem())
        return Observable<[PromotionVmItem]>.just(result)
    }
    lazy var manualCoupon: Observable<[PromotionVmItem]> = Observable.combineLatest(bonusCoupons, rebatePromotions).map { (bonusCoupons, rebateEvents) -> [PromotionVmItem] in
        let rebateIsAutoUse = rebateEvents.contains(where: {$0.isAutoUse})
        let result: [PromotionVmItem] = bonusCoupons
            .filter({ $0.isFromEvent() }) // is Rebate or Product
            .filter({ (coupon) in
                if rebateIsAutoUse, coupon is BonusCoupon.Rebate {
                    return false
                }
                return true
            }).sorted(by: { (b1: BonusCoupon, b2: BonusCoupon) in
                let date1 = b1.updatedDate.convertToDate()
                let date2 = b2.updatedDate.convertToDate()
                return date1 > date2
            }).map({ (bonusCoupon: BonusCoupon) -> PromotionVmItem in
                return bonusCoupon as! PromotionVmItem
            })
        return result
    }
    
    init(promotionUseCase: PromotionUseCase, playerUseCase: PlayerDataUseCase) {
        self.promotionUseCase = promotionUseCase
        self.playerUseCase = playerUseCase
    }
    
    lazy var playerLevel = playerUseCase.loadPlayer().map{ $0.playerInfo.level.description }
    
    func fetchData() {
        trigerRefresh.accept(())
    }
    
    func setCouponFilter(_ filter: PromotionFilter, _ selectedProductTags: [PromotionFilter.Product]) {
        self.filterOfSorce.accept(filter)
        self.filterOfProduct.accept(selectedProductTags)
    }
    
    func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions> {
        promotionUseCase.getPromotionDetail(promotionId: promotionId)
    }
    
    func requestCouponApplication(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
        return self.promotionUseCase.requestBonusCoupon(bonusCoupon: bonusCoupon)
    }
    
    private func transfer(_ filterOfProduct: PromotionFilter.Product) -> ProductType {
        switch filterOfProduct {
        case .Sport:
            return .sbk
        case .Slot:
            return .slot
        case .Casino:
            return .casino
        case .Numbergame:
            return .numbergame
        }
    }
}

protocol PromotionVmItem {
    var displayAmount: String { get }
    var issueNo: String { get }
    var title: String { get }
    var subTitle: String { get }
    var message: String { get }
    var icon: String { get }
    var id: String { get }
    var displayInformPlayerDate: String { get }
    var displayPercentage: String { get }
    var displayLevel: String? { get }
    var displayMaxAmount: String { get }
}

protocol BonusCouponItem: PromotionVmItem {
    var validPeriod: ValidPeriod { get }
    var couponState: CouponStatus { get }
    var rawValue: BonusCoupon { get }
    var displayBetMultiple: String { get }
    var displayMinCapital: String { get }
}

protocol PromotionEventItem: PromotionVmItem {
    var expireDate: Date { get }
    func isAutoUse() -> Bool
}

extension Array where Element: PromotionVmItem {
    func mapToItem() -> [Element] {
        return self
    }
}
