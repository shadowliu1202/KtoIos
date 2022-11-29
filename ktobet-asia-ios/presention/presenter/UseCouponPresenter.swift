import SharedBu
import UIKit

protocol UseCouponPresenter {
    func showAlert(_ title: String?, _ message: String?, confirm: (() -> Void)?, confirmText: String?, cancel: (() -> Void)?, cancelText: String?)
    func presentTurnOverLockedDialog(turnOver: TurnOverDetail, confirmAction: @escaping () -> ())
    func presentTurnOverApproveDialog(title: String, turnOver: TurnOverDetail, confirmAction: @escaping () -> (), cancelAction: @escaping () -> ())
    func presentConfirmUseDialog(title: String, turnOver: TurnOverHint, confirmAction: @escaping () -> (), cancelAction: @escaping () -> ())
}

class UseCouponPresenterImpl: UseCouponPresenter {
    
    let alert: AlertProtocol
    
    init(alert: AlertProtocol = Alert.shared) {
        self.alert = alert
    }
    
    func showAlert(_ title: String?, _ message: String?, confirm: (() -> Void)?, confirmText: String?, cancel: (() -> Void)?, cancelText: String?) {
        alert.show(title, message, confirm: confirm, confirmText: confirmText, cancel: cancel, cancelText: cancelText)
    }
    
    func presentTurnOverLockedDialog(turnOver: TurnOverDetail, confirmAction: @escaping () -> ()) {
        if let alertView = UIStoryboard(name: "Promotion", bundle: nil)
            .instantiateViewController(withIdentifier: "PromotionAlert1ViewController") as? PromotionAlert1ViewController,
           let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController
        {
            alertView.turnOver = turnOver
            alertView.confirmAction = confirmAction
            alertView.view.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
            alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            topVc.present(alertView, animated: true, completion: nil)
        }
    }
    
    func presentTurnOverApproveDialog(title: String, turnOver: TurnOverDetail, confirmAction: @escaping () -> (), cancelAction: @escaping () -> ()) {
        if let alertView = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionAlert2ViewController") as? PromotionAlert2ViewController,
           let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController
        {
            alertView.titleString = Localize.string("bonus_receive_confirm", title)
            alertView.confirmAction = confirmAction
            alertView.cancelAction = cancelAction
            alertView.turnOver = turnOver
            alertView.view.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
            alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            topVc.present(alertView, animated: true, completion: nil)
        }
    }
    
    func presentConfirmUseDialog(title: String, turnOver: TurnOverHint, confirmAction: @escaping () -> (), cancelAction: @escaping () -> ()) {
        if let alertView = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionAlert3ViewController") as? PromotionAlert3ViewController,
           let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController
        {
            alertView.titleString = Localize.string("bonus_receive_confirm", title)
            alertView.confirmAction = confirmAction
            alertView.cancelAction = cancelAction
            alertView.turnOver = turnOver
            alertView.view.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
            alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            topVc.present(alertView, animated: true, completion: nil)
        }
    }
}
