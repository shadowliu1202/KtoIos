import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SubUseBonusCoupon: UseBonusCoupon {
    override class func confirm(waiting: WaitingConfirm, bonusCoupon: BonusCoupon) -> Completable {
        switch waiting {
        case let waiting as ConfirmUseCouponFail:
            return waiting.execute(confirm: showUseCouponFailDialog(throwable: waiting.throwable))
        case is UseCouponSucceeded:
            return Completable.create { (completable) -> Disposable in
                NavigationManagement.sharedInstance.popViewController()
                return Disposables.create {}
            }
        default:
            return super.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
        }
    }
}

class UseBonusCoupon {
    class func confirm(waiting: WaitingConfirm, bonusCoupon: BonusCoupon) -> Completable {
        switch waiting {
        case let waiting as ConfirmUsageFull:
            return waiting.execute(confirm: createNotifyDialog(title: Localize.string("bonus_couponstatus_full_title"), message: Localize.string("bonus_quota_is_full_message")))
        case let waiting as ConfirmUseBonusCoupon:
            return waiting.execute(confirm: createUseCouponDialog(bonusCoupon: bonusCoupon)).flatMapCompletable({ (waiting) in
                confirm(waiting: waiting, bonusCoupon: bonusCoupon)
            })
        case let waiting as ConfirmLockedBonusCalculating:
            return waiting.execute(confirm: createNotifyDialog(title: Localize.string("bonus_applicationtips"), message: Localize.string("bonus_compute")))
        case let waiting as ConfirmBonusLocked:
            return waiting.execute(confirm: createNotifyDialog(title: Localize.string("bonus_applicationtips"), turnOver: waiting.turnOver))
        case let waiting as ConfirmLockedBonusHintForRebateCoupon:
            return waiting.execute(confirm: createTurnOverHintApprovedDialog(turnOver: waiting.turnOver, bonusCoupon: bonusCoupon)).flatMapCompletable({ (waiting) in
                confirm(waiting: waiting, bonusCoupon: bonusCoupon)
            })
        case let waiting as ConfirmLockedBonusHintForNoTurnOverCoupon:
            return waiting.execute(confirm: createTurnOverHintApprovedDialog(turnOver: waiting.turnOver, bonusCoupon: bonusCoupon)).flatMapCompletable({ (waiting) in
                confirm(waiting: waiting, bonusCoupon: bonusCoupon)
            })
        case let waiting as ConfirmAutoUse:
            return waiting.execute(confirm: createAutoUsedDialog()).flatMapCompletable { (waiting) in
                confirm(waiting: waiting, bonusCoupon: bonusCoupon)
            }
        case let waiting as ConfirmUseWithTurnOver:
            return waiting.execute(confirm: createUseCouponConfirmDialog(turnOver: waiting.hint, title: bonusCoupon.name)).flatMapCompletable({ (waiting) in
                confirm(waiting: waiting, bonusCoupon: bonusCoupon)
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


    private class func createNotifyDialog(title: String, message: String) -> Completable {
        return Completable.create { (completable) -> Disposable in
            Alert.show(title, message, confirm: {
                completable(.completed)
            }, confirmText: Localize.string("common_confirm"), cancel: nil)
            return Disposables.create {}
        }
    }

    private class func createUseCouponDialog(bonusCoupon: BonusCoupon) -> Single<Bool> {
        if let coupon = bonusCoupon as? BonusCoupon.FreeBet {
            return createUseCouponConfirmDialog(title: coupon.name, message: Localize.string("bonus_usefreebet"))
        } else if let coupon = bonusCoupon as? BonusCoupon.DepositReturn {
            return createUseCouponConfirmDialog(title: coupon.name, message: Localize.string("bonus_usedepositbonus"))
        } else {
            return Single.just(false)
        }
    }

    private class func createUseCouponConfirmDialog(title: String, message: String) -> Single<Bool> {
        return Single<Bool>.create(subscribe: { single in
            Alert.show(title, message, confirm: {
                        single(.success(true))
                       },
                       confirmText: Localize.string("common_confirm"),
                       cancel: {
                        single(.success(false))
                       },
                       cancelText: Localize.string("bonus_waiting"))
            return Disposables.create()
        })
    }

    private class func createAutoUsedDialog() -> Single<Bool> {
        return Single<Bool>.create(subscribe: { single in
            Alert.show(nil, Localize.string("bonus_allowautouse"), confirm: {
                        single(.success(true))
                       },
                       confirmText: Localize.string("common_allow"),
                       cancel: {
                        single(.success(false))
                       },
                       cancelText: Localize.string("common_skip"))
            return Disposables.create()
        })
    }

    private class func createNotifyDialog(title: String, turnOver: TurnOverDetail) -> Completable {
        return Completable.create { (completable) -> Disposable in
            if let alertView = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionAlert1ViewController") as? PromotionAlert1ViewController, let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                alertView.turnOver = turnOver
                alertView.confirmAction = { completable(.completed) }
                alertView.view.backgroundColor = UIColor.black80
                alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                topVc.present(alertView, animated: true, completion: nil)
            }
            return Disposables.create {}
        }
    }

    private class func createTurnOverHintApprovedDialog(turnOver: TurnOverDetail, bonusCoupon: BonusCoupon) -> Single<Bool> {
        var title = ""
        switch bonusCoupon.bonusType {
        case .freebet:
            title = Localize.string("bonus_bonustype_1")
        case .depositbonus, .levelbonus:
            title = Localize.string("bonus_bonustype_2_2")
        case .product:
            title = Localize.string("bonus_bonustype_3")
        case .rebate:
            title = Localize.string("bonus_bonustype_4")
        default:
            break
        }
        
        return Single<Bool>.create(subscribe: { single in
            if let alertView = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionAlert2ViewController") as? PromotionAlert2ViewController, let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                alertView.titleString = Localize.string("bonus_receive_confirm", title)
                alertView.confirmAction = { single(.success(true)) }
                alertView.cancelAction = { single(.success(false)) }
                alertView.turnOver = turnOver
                alertView.view.backgroundColor = UIColor.black80
                alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                topVc.present(alertView, animated: true, completion: nil)
            }
            return Disposables.create()
        })
    }

    private class func createUseCouponConfirmDialog(turnOver: TurnOverHint, title: String) -> Single<Bool> {
        return Single<Bool>.create(subscribe: { single in
            if let alertView = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionAlert3ViewController") as? PromotionAlert3ViewController, let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                alertView.titleString = Localize.string("bonus_receive_confirm", title)
                alertView.confirmAction = { single(.success(true)) }
                alertView.cancelAction = { single(.success(false)) }
                alertView.turnOver = turnOver
                alertView.view.backgroundColor = UIColor.black80
                alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                topVc.present(alertView, animated: true, completion: nil)
            }
            return Disposables.create()
        })
    }

    fileprivate class func showUseCouponFailDialog(throwable: ApiException) -> Completable {
        var title = ""
        var message = ""
        switch throwable {
        case is BonusBalanceLowerMinimumLimit:
            title = Localize.string("bonus_condition_error")
            message = Localize.string("bonus_error_balance_limit")
        case is BonusCouponDepositAmountOrTimesNotEnough:
            title = Localize.string("bonus_condition_error")
            message = Localize.string("bonus_deposit_not_satisfied")
        case is BonusReachTheApplicantLimitation:
            title = Localize.string("bonus_quota_is_full")
            message = Localize.string("bonus_error_bonus_quota_is_full")
        case is BonusCouponIsNotExist:
            title = Localize.string("bonus_use_expired_bonus_title")
            message = Localize.string("bonus_use_expired_bonus_content")
        default:
            title = Localize.string("bonus_condition_error")
            message = Localize.string("bonus_usebonus_fail")
            break
        }
        return Completable.create { (completable) -> Disposable in
            Alert.show(title, message, confirm: {
                completable(.completed)
            }, confirmText: Localize.string("common_confirm"), cancel: nil)
            return Disposables.create {}
        }
    }
}

