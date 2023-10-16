import Foundation
import RxCocoa
import RxSwift
import sharedbu
import SwiftUI

protocol CouponFilterable: ObservableObject {
  var promotionTags: [PromotionTag] { get set }
  var selectedPromotionFilter: PromotionFilter { get set }
  var selectedProductFilters: Set<PromotionFilter.Product> { get set }
}

class PromotionViewModel: CouponFilterable {
  @Published var promotionTags: [PromotionTag] = []
  @Published var selectedPromotionFilter: PromotionFilter = .all
  @Published var selectedProductFilters: Set<PromotionFilter.Product> = [
    .Sport,
    .Slot,
    .Casino,
    .Numbergame,
    .Arcade
  ]
  
  private let promotionUseCase: PromotionUseCase
  private let playerUseCase: PlayerDataUseCase

  private lazy var bonusCoupons = self.promotionUseCase.getBonusCoupons().asObservable().share()
  private lazy var productPromotions = self.promotionUseCase.getProductPromotionEvents().asObservable().share()
  private lazy var rebatePromotions = self.promotionUseCase.getRebatePromotionEvents().asObservable().share()
  private lazy var cashBackPromotions = self.promotionUseCase.getVVIPCashbackPromotionEvents().asObservable().share()

  lazy var trigerRefresh = PublishSubject<Void>()
  private lazy var freeBetCoupon = self.bonusCoupons.forceCast(BonusCoupon.FreeBet.self)
  private lazy var depositReturnCoupon = self.bonusCoupons.forceCast(BonusCoupon.DepositReturn.self)
  private lazy var productOfBonusCoupon = self.bonusCoupons.forceCast(BonusCoupon.Product.self)
  private lazy var productPromotionSummary = Observable.combineLatest(productOfBonusCoupon, productPromotions)
  private lazy var rebateOfBonusCoupon = self.bonusCoupons.forceCast(BonusCoupon.Rebate.self)
  private lazy var rebatePromotionSummary = Observable.combineLatest(rebateOfBonusCoupon, rebatePromotions)
    .map { coupon, rebate -> ([BonusCoupon.Rebate], [PromotionEvent.Rebate]) in
      if rebate.contains(where: { $0.isAutoUse }) {
        return ([], rebate)
      }
      return (coupon, rebate)
    }

  private lazy var cashBackOfBonusCoupon = self.bonusCoupons.forceCast(BonusCoupon.VVIPCashback.self)
  private lazy var cashBackPromotionSummary = Observable.combineLatest(cashBackOfBonusCoupon, cashBackPromotions)
  private var filterOfSorce = BehaviorRelay<PromotionFilter>(value: .all)
  private(set) var sectionHeaders: [String] = []
  lazy var dataSource = Observable.combineLatest(trigerRefresh, filterOfSorce)
    .flatMap { [unowned self] _, selected -> Observable<[[PromotionVmItem]]> in
      switch selected {
      case .all:
        self.sectionHeaders = [
          Localize.string("bonus_bonustype_manual"),
          Localize.string("bonus_bonustype_7"),
          Localize.string("bonus_bonustype_1"),
          Localize.string("bonus_bonustype_2"),
          Localize.string("bonus_bonustype_3"),
          Localize.string("bonus_bonustype_4")
        ]
        return Observable.combineLatest(
          self.manualCoupon,
          self.cashBacks,
          self.freeBets,
          self.depositReturns,
          self.products,
          self.rebates).map({ [$0, $1, $2, $3, $4, $5] })
      case .manual:
        self.sectionHeaders.removeAll()
        return self.manualCoupon.map({ [$0] })
      case .freeBet:
        self.sectionHeaders.removeAll()
        return self.freeBets.map({ [$0] })
      case .depositReturn:
        self.sectionHeaders.removeAll()
        return self.depositReturns.map({ [$0] })
      case .product:
        self.sectionHeaders.removeAll()
        return self.productsWithFilter.map({ [$0] })
      case .rebate:
        self.sectionHeaders.removeAll()
        return self.rebates.map({ [$0] })
      case .cashBack:
        self.sectionHeaders.removeAll()
        return self.cashBacks.map({ [$0] })
      }
    }

  lazy var filterSource = trigerRefresh.flatMap({ [unowned self] in
    Observable.combineLatest(
      self.manualCoupon,
      self.cashBacks,
      self.freeBets,
      self.depositReturns,
      self.products,
      self.rebates)
      .map(
        { [unowned self] manualCoupons, cashBacks, freebets, depositReturns, products, rebates -> [(PromotionFilter, Int)] in
          let allCount = manualCoupons.count + cashBacks.count + freebets.count + depositReturns.count + products
            .count + rebates.count
          var filter: [(PromotionFilter, Int)] = [
            (.all, allCount),
            (.manual, manualCoupons.count),
            (.freeBet, freebets.count),
            (.depositReturn, depositReturns.count),
            (.product, products.count),
            (.rebate, rebates.count)
          ]
          if cashBacks.count > 0 {
            filter.insert((.cashBack, cashBacks.count), at: 2)
          }
          return filter
        })
  })
  private lazy var freeBets: Observable<[PromotionVmItem]> = self.freeBetCoupon.map({ $0.mapToItem() })
  private lazy var depositReturns: Observable<[PromotionVmItem]> = self.depositReturnCoupon.map({ $0.mapToItem() })
  private var filterOfProduct = BehaviorRelay<[PromotionFilter.Product]>(value: [.Sport, .Slot, .Casino, .Numbergame])

  private lazy var productsWithFilter = Observable.combineLatest(filterOfProduct, self.productPromotionSummary)
    .flatMapLatest({ [unowned self] filters, summary -> Observable<[PromotionVmItem]> in
      let (bonusProducts, promotionProducts) = summary
      var bonus: [BonusCoupon.Product] = []
      var promotions: [PromotionEvent.Product] = []
      var filterTypes = filters.map({ [unowned self] in self.transfer($0) })

      bonusProducts.forEach({ product in
        if filterTypes.contains(product.productType) {
          bonus.append(product)
        }
      })

      promotionProducts.forEach({ product in
        if filterTypes.contains(product.type) {
          promotions.append(product)
        }
      })

      var result: [PromotionVmItem] = []
      result.append(contentsOf: bonus.mapToItem())
      result.append(contentsOf: promotions.mapToItem())
      return Observable<[PromotionVmItem]>.just(result)
    })

  private lazy var products: Observable<[PromotionVmItem]> = self.productPromotionSummary
    .flatMapLatest { bonusProducts, promotionProducts -> Observable<[PromotionVmItem]> in
      var result: [PromotionVmItem] = []
      result.append(contentsOf: bonusProducts.mapToItem())
      result.append(contentsOf: promotionProducts.mapToItem())
      return Observable<[PromotionVmItem]>.just(result)
    }

  private lazy var rebates: Observable<[PromotionVmItem]> = self.rebatePromotionSummary
    .flatMapLatest { bonusRebates, promotionRebates -> Observable<[PromotionVmItem]> in
      var result: [PromotionVmItem] = []
      result.append(contentsOf: bonusRebates.mapToItem())
      result.append(contentsOf: promotionRebates.mapToItem())
      return Observable<[PromotionVmItem]>.just(result)
    }

  private lazy var cashBacks: Observable<[PromotionVmItem]> = self.cashBackPromotionSummary
    .flatMapLatest { bonusCashBacks, promotionCashBacks -> Observable<[PromotionVmItem]> in
      var result: [PromotionVmItem] = []
      result.append(contentsOf: bonusCashBacks.mapToItem())
      result.append(contentsOf: promotionCashBacks.mapToItem())

      return Observable<[PromotionVmItem]>.just(result)
    }

  private lazy var manualCoupon: Observable<[PromotionVmItem]> = Observable.combineLatest(bonusCoupons, rebatePromotions)
    .map { bonusCoupons, rebateEvents -> [PromotionVmItem] in
      let rebateIsAutoUse = rebateEvents.contains(where: { $0.isAutoUse })
      let result: [PromotionVmItem] = bonusCoupons
        .filter({ $0.isFromEvent() }) // is Rebate or Product or VVIPCashback
        .filter({ coupon in
          if rebateIsAutoUse, coupon is BonusCoupon.Rebate {
            return false
          }
          return true
        }).sorted(by: { (b1: BonusCoupon, b2: BonusCoupon) in
          let date1 = b1.updatedDate.convertToDate()
          let date2 = b2.updatedDate.convertToDate()
          return date1 > date2
        }).map({ (bonusCoupon: BonusCoupon) -> PromotionVmItem in
          bonusCoupon as! PromotionVmItem
        })
      return result
    }

  lazy var playerLevel = playerUseCase.loadPlayer().map { $0.playerInfo.level.description }

  init(promotionUseCase: PromotionUseCase, playerUseCase: PlayerDataUseCase) {
    self.promotionUseCase = promotionUseCase
    self.playerUseCase = playerUseCase
  }

  func fetchData() {
    trigerRefresh.onNext(())
  }

  func setCouponFilter(_ selectedPromotionFilter: PromotionFilter, _ selectedProductFilters: [PromotionFilter.Product]) {
    self.filterOfSorce.accept(selectedPromotionFilter)
    self.filterOfProduct.accept(selectedProductFilters)
  }

  func getPromotionDetail(id promotionId: String) -> Driver<PromotionDescriptions> {
    promotionUseCase.getPromotionDetail(promotionId: promotionId)
      .map { promotionDescriptions in
        let content = promotionDescriptions.content.htmlToString
        let rule = promotionDescriptions.rules.htmlToString
        return PromotionDescriptions(content: content, rules: rule)
      }.asDriver(onErrorJustReturn: PromotionDescriptions(content: "", rules: ""))
  }

  func getCashBackSettings(id promotionId: String) -> Single<[CashBackSetting]> {
    promotionUseCase.getCashBackSettings(displayId: promotionId)
  }

  func requestCouponApplication(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
    self.promotionUseCase.requestBonusCoupon(bonusCoupon: bonusCoupon)
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
    case .Arcade:
      return .arcade
    }
  }
}

protocol PromotionVmItem {
  var stampIcon: String? { get }
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

extension PromotionVmItem {
  var stampIcon: String? { nil }
}

protocol BonusCouponItem: PromotionVmItem {
  var validPeriod: ValidPeriod { get }
  var couponState: CouponStatus { get }
  var rawValue: BonusCoupon { get }
  var displayBetMultiple: String { get }
  var displayMinCapital: String { get }
}

protocol HasAmountLimitationItem: BonusCouponItem where Self: HasAmountLimitation {
  var watermarkIcon: UIImage? { get }
}

extension HasAmountLimitationItem {
  var watermarkIcon: UIImage? {
    switch self.getFullType() {
    case .none:
      return nil
    case .daily:
      return UIImage(named: "promotionDailyFull")
    case .complete:
      return UIImage(named: "promotionIsFull")
    default:
      return nil
    }
  }
}

protocol PromotionEventItem: PromotionVmItem {
  var expireDate: Date { get }
  func isAutoUse() -> Bool
}

extension Array where Element: PromotionVmItem {
  func mapToItem() -> [Element] {
    self
  }
}
