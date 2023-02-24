import Foundation
import RxSwift
import SharedBu

class WaitingConfirm {
  fileprivate func addUseCouponHandler(_ error: Error) -> Single<WaitingConfirm> {
    guard let exception = error as? ApiException else {
      return Single.error(error)
    }
    switch exception {
    case is BonusBalanceLowerMinimumLimit,
         is BonusCouponDepositAmountOrTimesNotEnough,
         is BonusCouponIsNotExist,
         is BonusCouponIsUsed,
         is BonusReachTheApplicantLimitation,
         is BonusReachTheDailyLimitation:
      return Single.just(ConfirmUseCouponFail(throwable: exception))
    default:
      return Single.error(error)
    }
  }
}

class ConfirmUsageFull: WaitingConfirm {
  func execute(confirm: Completable) -> Completable {
    confirm
  }
}

class ConfirmUseBonusCoupon: WaitingConfirm {
  private var useCase: CouponUseCase
  private var bonusCoupon: BonusCoupon
  init(useCase: CouponUseCase, bonusCoupon: BonusCoupon) {
    self.useCase = useCase
    self.bonusCoupon = bonusCoupon
  }

  func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
    confirm.flatMap({ confirm in
      if confirm == false {
        return Single.just(DoNothing())
      }
      else if let rebateBonusCoupon = self.bonusCoupon as? BonusCoupon.Rebate {
        return Single.just(ConfirmAutoUse(useCase: self.useCase, bonusCoupon: rebateBonusCoupon))
      }
      else {
        return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
          .andThen(Single.just(UseCouponSucceeded()))
          .catch { error -> Single<WaitingConfirm> in
            self.addUseCouponHandler(error)
          }
      }
    })
  }
}

class ConfirmUseCouponFail: WaitingConfirm {
  private(set) var throwable: ApiException
  init(throwable: ApiException) {
    self.throwable = throwable
  }

  func execute(confirm: Completable) -> Completable {
    confirm
  }
}

class ConfirmLockedBonusCalculating: WaitingConfirm {
  func execute(confirm: Completable) -> Completable {
    confirm
  }
}

class ConfirmBonusLocked: WaitingConfirm {
  private(set) var turnOver: TurnOverDetail
  init(turnOver: TurnOverDetail) {
    self.turnOver = turnOver
  }

  func execute(confirm: Completable) -> Completable {
    confirm
  }
}

class ConfirmLockedBonusHintForNoTurnOverCoupon: WaitingConfirm {
  private var useCase: CouponUseCase
  private(set) var turnOver: TurnOverDetail
  private var bonusCoupon: BonusCoupon
  init(useCase: CouponUseCase, turnOver: TurnOverDetail, bonusCoupon: BonusCoupon) {
    self.useCase = useCase
    self.turnOver = turnOver
    self.bonusCoupon = bonusCoupon
  }

  func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
    confirm.flatMap({
      if $0 {
        return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
          .andThen(Single.just(UseCouponSucceeded()))
          .catch { error -> Single<WaitingConfirm> in
            self.addUseCouponHandler(error)
          }
      }
      else {
        return Single.just(DoNothing())
      }
    })
  }
}

class ConfirmLockedBonusHintForRebateCoupon: WaitingConfirm {
  private var useCase: CouponUseCase
  private(set) var turnOver: TurnOverDetail
  private(set) var bonusCoupon: BonusCoupon.Rebate
  init(useCase: CouponUseCase, turnOver: TurnOverDetail, bonusCoupon: BonusCoupon.Rebate) {
    self.useCase = useCase
    self.turnOver = turnOver
    self.bonusCoupon = bonusCoupon
  }

  func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
    confirm.map {
      if $0 {
        return ConfirmAutoUse(useCase: self.useCase, bonusCoupon: self.bonusCoupon)
      }
      else {
        return DoNothing()
      }
    }
  }
}

class ConfirmAutoUse: WaitingConfirm {
  private var useCase: CouponUseCase
  private var bonusCoupon: BonusCoupon.Rebate
  init(useCase: CouponUseCase, bonusCoupon: BonusCoupon.Rebate) {
    self.useCase = useCase
    self.bonusCoupon = bonusCoupon
  }

  func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
    confirm.flatMap({
      self.useCase.useRebateCoupon(bonusCoupon: self.bonusCoupon, autoUse: $0)
        .andThen(Single.just(UseCouponSucceeded()))
        .catch { error -> Single<WaitingConfirm> in
          self.addUseCouponHandler(error)
        }
    })
  }
}

class ConfirmUseWithTurnOver: WaitingConfirm {
  private(set) var hint: TurnOverHint
  private var useCase: CouponUseCase
  private var bonusCoupon: BonusCoupon
  init(hint: TurnOverHint, useCase: CouponUseCase, bonusCoupon: BonusCoupon) {
    self.hint = hint
    self.useCase = useCase
    self.bonusCoupon = bonusCoupon
  }

  func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
    confirm.flatMap({
      if $0 {
        return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
          .andThen(Single.just(UseCouponSucceeded()))
          .catch { error -> Single<WaitingConfirm> in
            self.addUseCouponHandler(error)
          }
      }
      else {
        return Single.just(DoNothing())
      }
    })
  }
}

class DoNothing: WaitingConfirm { }
class UseCouponSucceeded: WaitingConfirm { }
