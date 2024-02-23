import Foundation
import RxSwift
import sharedbu

protocol PromotionUseCase {
  func searchBonusCoupons(
    keyword: String,
    from: Date,
    to: Date,
    productTypes: [ProductType],
    privilegeTypes: [PrivilegeType],
    sortingBy: SortingType,
    page: Int) -> Single<CouponHistorySummary>

  func getBonusCoupons() -> Single<[BonusCoupon]>
  func getProductPromotionEvents() -> Single<[PromotionEvent.Product]>
  func getRebatePromotionEvents() -> Single<[PromotionEvent.Rebate]>
  func getVVIPCashbackPromotionEvents() -> Single<[PromotionEvent.VVIPCashback]>

  func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions>
  func requestBonusCoupon(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm>
  func getCashBackSettings(displayId: String) -> Single<[CashBackSetting]>
}

protocol CouponUseCase {
  func useBonusCoupon(bonusCoupon: BonusCoupon) -> Completable
  func useRebateCoupon(bonusCoupon: BonusCoupon.Rebate, autoUse: Bool) -> Completable
}

class PromotionUseCaseImpl: PromotionUseCase, CouponUseCase {
  var promotionRepository: PromotionRepository!
  var playerRepository: PlayerRepository!

  init(_ promotionRepository: PromotionRepository, playerRepository: PlayerRepository) {
    self.promotionRepository = promotionRepository
    self.playerRepository = playerRepository
  }

  func searchBonusCoupons(
    keyword: String,
    from: Date,
    to: Date,
    productTypes: [ProductType],
    privilegeTypes: [PrivilegeType],
    sortingBy: SortingType,
    page: Int) -> Single<CouponHistorySummary>
  {
    promotionRepository.searchBonusCoupons(
      keyword: keyword,
      from: from,
      to: to,
      productTypes: productTypes,
      privilegeTypes: privilegeTypes,
      sortingBy: sortingBy,
      page: page)
  }

  func getBonusCoupons() -> Single<[BonusCoupon]> {
    promotionRepository.getBonusCoupons().map { [weak self] (coupons: [BonusCoupon]) -> [BonusCoupon] in
      guard let self else { return coupons }
      return self.filterLevelBonusCoupon(list: coupons)
        .sorted(by: { a, b in
          guard let a = a as? HasAmountLimitation, let b = b as? HasAmountLimitation else { return false }
          return !a.isFull() && b.isFull()
        })
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
    for eachCoupon in all {
      if let existCoupon = eachLevelCoupons.first(where: { $0.level == eachCoupon.level }) {
        self.keepEarlierCoupon(coupons: &eachLevelCoupons, existCoupon: existCoupon, eachCoupon: eachCoupon)
      }
      else {
        eachLevelCoupons.append(eachCoupon)
      }
    }
    return eachLevelCoupons
  }

  private func keepEarlierCoupon(
    coupons: inout [BonusCoupon.DepositReturnLevel],
    existCoupon: BonusCoupon.DepositReturnLevel,
    eachCoupon: BonusCoupon.DepositReturnLevel)
  {
    if isItem1AfterItem2(item1: existCoupon, item2: eachCoupon) {
      coupons = coupons.filter({ $0 != existCoupon })
      coupons.append(eachCoupon)
    }
  }

  private func isItem1AfterItem2(item1: BonusCoupon.DepositReturnLevel, item2: BonusCoupon.DepositReturnLevel) -> Bool {
    let period1 = item1.validPeriod
    let period2 = item2.validPeriod
    
    switch onEnum(of: period1) {
    case .always:
      return true
    case .duration(let duration1):
      switch onEnum(of: period2) {
      case .always:
        return false
      case .duration(let duration2):
        return duration1.start.convertToDate() > duration2.end.convertToDate()
      }
    }
  }

  func getProductPromotionEvents() -> Single<[PromotionEvent.Product]> {
    self.promotionRepository.getProductPromotions()
  }

  func getRebatePromotionEvents() -> Single<[PromotionEvent.Rebate]> {
    self.promotionRepository.getRebatePromotions()
  }

  func getVVIPCashbackPromotionEvents() -> Single<[PromotionEvent.VVIPCashback]> {
    self.promotionRepository.getCashbackPromotions()
  }

  func getPromotionDetail(promotionId: String) -> Single<PromotionDescriptions> {
    self.promotionRepository.getPromotionDetail(promotionId: promotionId)
  }

  func useBonusCoupon(bonusCoupon: BonusCoupon) -> Completable {
    self.promotionRepository.useCoupon(bonusCoupon: bonusCoupon, autoUse: false)
  }

  func useRebateCoupon(bonusCoupon: BonusCoupon.Rebate, autoUse: Bool) -> Completable {
    self.promotionRepository.useCoupon(bonusCoupon: bonusCoupon, autoUse: autoUse)
  }

  func requestBonusCoupon(bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
    switch onEnum(of: bonusCoupon) {
    case .depositReturn,
         .freeBet,
         .product,
         .vVIPCashback:
      return confirmUseBonusCoupon(bonusCoupon)
    case .rebate(let it):
      return confirmUseRebateCoupon(it)
    case .other:
      return Single.just(DoNothing())
    }
  }

  private func confirmUseBonusCoupon(_ bonusCoupon: BonusCoupon) -> Single<WaitingConfirm> {
    verifyDepositReturnCouponLimitation(bonusCoupon)
      .andThen(verifyAccountLockedBonus(bonusCoupon))
      .andThen(Single.just(ConfirmUseBonusCoupon(useCase: self, bonusCoupon: bonusCoupon)))
      .catch({ error -> Single<WaitingConfirm> in
        if let exception = error as? PromotionException {
          switch onEnum(of: exception) {
          case .blockedByLockedBonus(let it):
            return Single.just(ConfirmBonusLocked(turnOver: it.turnOver))
          case .depositBonusHasTurnOverException(let it):
            return Single.just(ConfirmUseWithTurnOver(hint: it.hint, useCase: self, bonusCoupon: bonusCoupon))
          case .depositCouponFullException:
            return Single.just(ConfirmUsageFull())
          case .hasLockedBonusHintException(let it):
            return Single.just(ConfirmLockedBonusHintForNoTurnOverCoupon(
              useCase: self,
              turnOver: it.turnOver,
              bonusCoupon: bonusCoupon))
          case .lockedBonusCalculatingException:
            return Single.just(ConfirmLockedBonusCalculating())
          }
        }
        return Single.error(error)
      })
  }

  private func verifyDepositReturnCouponLimitation(_ bonusCoupon: BonusCoupon) -> Completable {
    if let coupon = bonusCoupon as? BonusCoupon.DepositReturn, coupon.isFull() {
      return Completable.error(PromotionException.DepositCouponFullException())
    }
    else {
      return Completable.empty()
    }
  }

  private func verifyAccountLockedBonus(_ bonusCoupon: BonusCoupon) -> Completable {
    self.promotionRepository.hasAccountLockedBonus().flatMapCompletable({ [unowned self] hasLockedBonus in
      if hasLockedBonus, bonusCoupon.hasTurnOver() {
        return self.checkLockedBonusStatus().andThen(self.promotionRepository.getLockedBonusDetail()).flatMapCompletable({
          Completable.error(PromotionException.BlockedByLockedBonus(turnOver: $0))
        })
      }
      else if hasLockedBonus, !bonusCoupon.hasTurnOver() {
        return self.checkLockedBonusStatus().andThen(self.promotionRepository.getLockedBonusDetail()).flatMapCompletable({
          Completable.error(PromotionException.HasLockedBonusHintException(turnOver: $0))
        })
      }
      else if !hasLockedBonus, bonusCoupon.hasTurnOver() {
        return self.promotionRepository.getTurnOverDetail(bonusCoupon: bonusCoupon).flatMapCompletable({
          Completable.error(PromotionException.DepositBonusHasTurnOverException(hint: $0))
        })
      }
      else {
        return Completable.empty()
      }
    })
  }

  private func checkLockedBonusStatus() -> Completable {
    self.promotionRepository.isLockedBonusCalculating().flatMapCompletable({ calculating in
      if calculating {
        return Completable.error(PromotionException.LockedBonusCalculatingException())
      }
      else {
        return Completable.empty()
      }
    })
  }

  private func confirmUseRebateCoupon(_ bonusCoupon: BonusCoupon.Rebate) -> Single<WaitingConfirm> {
    verifyAccountLockedBonus(bonusCoupon)
      .andThen(Single.just(ConfirmUseBonusCoupon(useCase: self, bonusCoupon: bonusCoupon)))
      .catch({ error -> Single<WaitingConfirm> in
        if let exception = error as? PromotionException {
          switch onEnum(of: exception) {
          case .blockedByLockedBonus,
               .depositBonusHasTurnOverException,
               .depositCouponFullException:
            return Single.error(error)
          case .hasLockedBonusHintException(let it):
            return Single.just(ConfirmLockedBonusHintForRebateCoupon(
              useCase: self,
              turnOver: it.turnOver,
              bonusCoupon: bonusCoupon))
          case .lockedBonusCalculatingException:
            return Single.just(ConfirmLockedBonusCalculating())
          }
        }
        return Single.error(error)
      })
  }

  func getCashBackSettings(displayId: String) -> Single<[CashBackSetting]> {
    promotionRepository.getCashBackSettings(displayId: displayId)
  }
}
