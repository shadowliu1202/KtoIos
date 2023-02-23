import RxCocoa
import RxSwift
import SharedBu
import UIKit

class SubUseBonusCoupon: UseBonusCoupon {
  override func confirm(waiting: WaitingConfirm, bonusCoupon: BonusCoupon) -> Completable {
    switch waiting {
    case let waiting as ConfirmUseCouponFail where waiting.throwable is BonusCouponIsNotExist:
      return waiting.execute(confirm: showUseCouponFailDialog())
    case is UseCouponSucceeded:
      return Completable.create { _ -> Disposable in
        NavigationManagement.sharedInstance.popViewController()
        return Disposables.create { }
      }
    default:
      return super.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
    }
  }

  private func showUseCouponFailDialog() -> Completable {
    let title = Localize.string("bonus_use_expired_bonus_title")
    let message = Localize.string("bonus_use_expired_bonus_content")
    return Completable.create { [weak self] completable -> Disposable in
      self?.presenter.showAlert(
        title,
        message,
        confirm: {
          NavigationManagement.sharedInstance.popViewController()
          completable(.completed)
        },
        confirmText: Localize.string("common_confirm"),
        cancel: nil,
        cancelText: nil)

      return Disposables.create { }
    }
  }
}

class UseBonusCoupon {
  fileprivate let presenter: UseCouponPresenter

  init(presenter: UseCouponPresenter = UseCouponPresenterImpl()) {
    self.presenter = presenter
  }

  func confirm(waiting: WaitingConfirm, bonusCoupon: BonusCoupon) -> Completable {
    switch waiting {
    case let waiting as ConfirmUsageFull:
      return waiting.execute(confirm: createNotifyDialog(
        title: Localize.string("bonus_couponstatus_full_title"),
        message: Localize.string("bonus_quota_is_full_message")))
    case let waiting as ConfirmUseBonusCoupon:
      return waiting.execute(confirm: createUseCouponDialog(bonusCoupon: bonusCoupon))
        .flatMapCompletable({ [weak self] waiting in
          guard let self else { return .empty() }

          return self.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        })
    case let waiting as ConfirmLockedBonusCalculating:
      return waiting
        .execute(confirm: createNotifyDialog(
          title: Localize.string("bonus_applicationtips"),
          message: Localize.string("bonus_compute")))
    case let waiting as ConfirmBonusLocked:
      return waiting.execute(confirm: createTurnOverLockedDialog(turnOver: waiting.turnOver))
    case let waiting as ConfirmLockedBonusHintForRebateCoupon:
      return waiting
        .execute(confirm: createTurnOverHintApprovedDialog(turnOver: waiting.turnOver, bonusCoupon: bonusCoupon))
        .flatMapCompletable({ [weak self] waiting in
          guard let self else { return .empty() }

          return self.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        })
    case let waiting as ConfirmLockedBonusHintForNoTurnOverCoupon:
      return waiting
        .execute(confirm: createTurnOverHintApprovedDialog(turnOver: waiting.turnOver, bonusCoupon: bonusCoupon))
        .flatMapCompletable({ [weak self] waiting in
          guard let self else { return .empty() }

          return self.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        })
    case let waiting as ConfirmAutoUse:
      return waiting.execute(confirm: createAutoUsedDialog())
        .flatMapCompletable({ [weak self] waiting in
          guard let self else { return .empty() }

          return self.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        })
    case let waiting as ConfirmUseWithTurnOver:
      return waiting.execute(confirm: createUseCouponConfirmDialog(turnOver: waiting.hint, title: bonusCoupon.name))
        .flatMapCompletable({ [weak self] waiting in
          guard let self else { return .empty() }

          return self.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        })
    case is DoNothing:
      return Completable.empty()
    case let waiting as ConfirmUseCouponFail:
      return waiting.execute(confirm: showUseCouponFailDialog(throwable: waiting.throwable))
    case is UseCouponSucceeded:
      return Completable.empty()
    default:
      return Completable.empty()
    }
  }

  private func createNotifyDialog(title: String, message: String) -> Completable {
    Completable.create { [weak self] completable -> Disposable in
      self?.presenter.showAlert(
        title,
        message,
        confirm: { completable(.completed) },
        confirmText: Localize.string("common_confirm"),
        cancel: nil,
        cancelText: nil)

      return Disposables.create { }
    }
  }

  private func createUseCouponDialog(bonusCoupon: BonusCoupon) -> Single<Bool> {
    if let coupon = bonusCoupon as? BonusCoupon.FreeBet {
      return createUseCouponConfirmDialog(
        title: coupon.name,
        message: Localize.string("bonus_use_coupon", Localize.string("bonus_bonustype_1")))
    }
    else if let coupon = bonusCoupon as? BonusCoupon.DepositReturn {
      return createUseCouponConfirmDialog(
        title: coupon.name,
        message: Localize.string("bonus_use_coupon", Localize.string("bonus_bonustype_2_2")))
    }
    else if let coupon = bonusCoupon as? BonusCoupon.Rebate {
      return createUseCouponConfirmDialog(
        title: coupon.message,
        message: Localize.string("bonus_use_coupon", Localize.string("bonus_bonustype_4")))
    }
    else if let coupon = bonusCoupon as? BonusCoupon.VVIPCashback {
      return createUseCouponConfirmDialog(
        title: coupon.message,
        message: Localize.string("bonus_use_coupon", Localize.string("bonus_bonustype_7")))
    }
    else {
      return Single.just(false)
    }
  }

  private func createUseCouponConfirmDialog(title: String, message: String) -> Single<Bool> {
    Single<Bool>.create(subscribe: { [weak self] single in
      self?.presenter.showAlert(
        title,
        message,
        confirm: { single(.success(true)) },
        confirmText: Localize.string("common_confirm"),
        cancel: { single(.success(false)) },
        cancelText: Localize.string("common_cancel"))

      return Disposables.create()
    })
  }

  private func createAutoUsedDialog() -> Single<Bool> {
    Single<Bool>.create(subscribe: { [weak self] single in
      self?.presenter.showAlert(
        nil,
        Localize.string("bonus_allowautouse"),
        confirm: { single(.success(true)) },
        confirmText: Localize.string("common_allow"),
        cancel: { single(.success(false)) },
        cancelText: Localize.string("common_skip"))

      return Disposables.create()
    })
  }

  private func createTurnOverLockedDialog(turnOver: TurnOverDetail) -> Completable {
    Completable.create { [weak self] completable -> Disposable in
      self?.presenter.presentTurnOverLockedDialog(
        turnOver: turnOver,
        confirmAction: { completable(.completed) })

      return Disposables.create { }
    }
  }

  private func createTurnOverHintApprovedDialog(turnOver: TurnOverDetail, bonusCoupon: BonusCoupon) -> Single<Bool> {
    var title = ""
    switch bonusCoupon.bonusType {
    case .freebet:
      title = Localize.string("bonus_bonustype_1")
    case .depositbonus,
         .levelbonus:
      title = Localize.string("bonus_bonustype_2_2")
    case .product:
      title = Localize.string("bonus_bonustype_3")
    case .rebate:
      title = Localize.string("bonus_bonustype_4")
    default:
      break
    }

    return Single<Bool>.create(subscribe: { [weak self] single in
      self?.presenter.presentTurnOverApproveDialog(
        title: title,
        turnOver: turnOver,
        confirmAction: { single(.success(true)) },
        cancelAction: { single(.success(false)) })

      return Disposables.create()
    })
  }

  private func createUseCouponConfirmDialog(turnOver: TurnOverHint, title: String) -> Single<Bool> {
    Single<Bool>.create(subscribe: { [weak self] single in
      self?.presenter.presentConfirmUseDialog(
        title: title,
        turnOver: turnOver,
        confirmAction: { single(.success(true)) },
        cancelAction: { single(.success(false)) })

      return Disposables.create()
    })
  }

  private func showUseCouponFailDialog(throwable: ApiException) -> Completable {
    var title = ""
    var message = ""

    switch throwable {
    case is BonusBalanceLowerMinimumLimit:
      title = Localize.string("bonus_condition_error")
      message = Localize.string("bonus_error_balance_limit")
    case is BonusCouponDepositAmountOrTimesNotEnough:
      title = Localize.string("bonus_condition_error")
      message = Localize.string("bonus_deposit_not_satisfied")
    case is BonusReachTheApplicantLimitation,
         is BonusReachTheDailyLimitation:
      title = Localize.string("bonus_quota_is_full")
      message = Localize.string("bonus_error_bonus_quota_is_full")
    case is BonusCouponIsNotExist:
      title = Localize.string("bonus_use_expired_bonus_title")
      message = Localize.string("bonus_use_expired_bonus_content")
    default:
      title = Localize.string("bonus_condition_error")
      message = Localize.string("bonus_usebonus_fail")
    }

    return Completable.create { [weak self] completable -> Disposable in
      self?.presenter.showAlert(
        title,
        message,
        confirm: { completable(.completed) },
        confirmText: Localize.string("common_confirm"),
        cancel: nil,
        cancelText: nil)

      return Disposables.create { }
    }
  }
}
