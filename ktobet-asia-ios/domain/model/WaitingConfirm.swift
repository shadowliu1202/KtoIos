import Foundation
import RxSwift
import SharedBu

class WaitingConfirm {
    fileprivate func addUseCouponHandler(_ error : Error) -> Single<WaitingConfirm> {
        let exception = ExceptionFactory.create(error)
        switch exception {
        case is BonusBalanceLowerMinimumLimit,
             is BonusCouponDepositAmountOrTimesNotEnough,
             is BonusCouponIsUsed,
             is BonusReachTheApplicantLimitation,
             is BonusReachTheDailyLimitation,
             is BonusCouponIsNotExist:
            return Single.just(ConfirmUseCouponFail(throwable: exception))
        default:
            return Single.error(error)
        }
    }
}

class ConfirmUsageFull: WaitingConfirm {
    func execute(confirm: Completable) -> Completable {
        return confirm
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
        return confirm.flatMap({
            if ($0) {
                return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
                    .andThen(Single.just(UseCouponSucceeded()))
                    .catchError { (error) -> Single<WaitingConfirm> in
                        return self.addUseCouponHandler(error)
                    }
            } else {
                return Single.just(DoNothing())
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
        return confirm
    }
}
class ConfirmLockedBonusCalculating: WaitingConfirm {
    func execute(confirm: Completable) -> Completable {
        return confirm
    }
}
class ConfirmBonusLocked: WaitingConfirm {
    private(set)var turnOver: TurnOverDetail
    init(turnOver: TurnOverDetail) {
        self.turnOver = turnOver
    }
    func execute(confirm: Completable) -> Completable {
        return confirm
    }
}
class ConfirmLockedBonusHintForNoTurnOverCoupon: WaitingConfirm {
    private var useCase: CouponUseCase
    private(set)var turnOver: TurnOverDetail
    private var bonusCoupon: BonusCoupon
    init(useCase: CouponUseCase, turnOver: TurnOverDetail, bonusCoupon: BonusCoupon) {
        self.useCase = useCase
        self.turnOver = turnOver
        self.bonusCoupon = bonusCoupon
    }
    func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
        return confirm.flatMap({
            if ($0) {
                return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
                    .andThen(Single.just(UseCouponSucceeded()))
                    .catchError { (error) -> Single<WaitingConfirm> in
                        return self.addUseCouponHandler(error)
                    }
            } else {
                return Single.just(DoNothing())
            }
        })
    }
}
class ConfirmLockedBonusHintForRebateCoupon: WaitingConfirm {
    private var useCase: CouponUseCase
    private(set)var turnOver: TurnOverDetail
    private(set)var bonusCoupon: BonusCoupon.Rebate
    init(useCase: CouponUseCase, turnOver: TurnOverDetail, bonusCoupon: BonusCoupon.Rebate) {
        self.useCase = useCase
        self.turnOver = turnOver
        self.bonusCoupon = bonusCoupon
    }
    func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
        return confirm.map {
            if ($0) {
                return ConfirmAutoUse(useCase: self.useCase, bonusCoupon: self.bonusCoupon)
            } else {
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
        return confirm.flatMap({
            return self.useCase.useRebateCoupon(bonusCoupon: self.bonusCoupon, autoUse: $0)
                .andThen(Single.just(UseCouponSucceeded()))
                .catchError { (error) -> Single<WaitingConfirm> in
                    return self.addUseCouponHandler(error)
                }
        })
    }
}
class ConfirmUseWithTurnOver: WaitingConfirm {
    private(set)var hint: TurnOverHint
    private var useCase: CouponUseCase
    private var bonusCoupon: BonusCoupon
    init(hint: TurnOverHint, useCase: CouponUseCase, bonusCoupon: BonusCoupon) {
        self.hint = hint
        self.useCase = useCase
        self.bonusCoupon = bonusCoupon
    }
    func execute(confirm: Single<Bool>) -> Single<WaitingConfirm> {
        return confirm.flatMap({
            if ($0) {
                return self.useCase.useBonusCoupon(bonusCoupon: self.bonusCoupon)
                    .andThen(Single.just(UseCouponSucceeded()))
                    .catchError { (error) -> Single<WaitingConfirm> in
                        return self.addUseCouponHandler(error)
                    }
            } else {
                return Single.just(DoNothing())
            }
        })
    }
}
class DoNothing : WaitingConfirm {}
class UseCouponSucceeded : WaitingConfirm{}
