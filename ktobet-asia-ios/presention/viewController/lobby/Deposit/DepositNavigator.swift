import Foundation
import SharedBu

protocol DepositNavigator {
    func toDepositOfflineConfirmPage()
    func toDepositHomePage()
    func toOnlineWebPage(url: String)
    func toCryptoWebPage(url: String)
    func toGuidePage()
}

class DepositNavigatorImpl: DepositNavigator {
    func toDepositOfflineConfirmPage() {
        NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositOfflineConfirmViewController.segueIdentifier, sender: nil)
    }
    
    func toDepositHomePage() {
        DispatchQueue.main.async {
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
        }
    }
    
    func toOnlineWebPage(url: String) {
        let title = Localize.string("common_kindly_remind")
        let message = Localize.string("deposit_thirdparty_transaction_remind")
        Alert.show(title, message, confirm: {
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: url)
        }, cancel: nil)
    }
    
    func toCryptoWebPage(url: String) {
        NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositCryptoViewController.segueIdentifier, sender: url)
    }
    
    func toGuidePage() {
        NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: CryptoGuideViewController.segueIdentifier, sender: nil)
    }
}
