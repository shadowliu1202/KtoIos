import Foundation
import SharedBu

protocol DepositNavigator {
  func toDepositOfflineConfirmPage()
  func toDepositHomePage(unwindSegueId: String)
  func toOnlineWebPage(url: String)
  func toGuidePage(_ playerLocale: SupportLocale)
}

class DepositNavigatorImpl: DepositNavigator {
  func toDepositOfflineConfirmPage() {
    NavigationManagement.sharedInstance.viewController.performSegue(
      withIdentifier: DepositOfflineConfirmViewController.segueIdentifier,
      sender: nil)
  }

  func toDepositHomePage(unwindSegueId: String) {
    DispatchQueue.main.async {
      NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: unwindSegueId, sender: nil)
    }
  }

  func toOnlineWebPage(url: String) {
    let title = Localize.string("common_kindly_remind")
    let message = Localize.string("deposit_thirdparty_transaction_remind")
    Alert.shared.show(title, message, confirm: {
      NavigationManagement.sharedInstance.viewController.performSegue(
        withIdentifier: DepositThirdPartWebViewController.segueIdentifier,
        sender: url)
    }, cancel: nil)
  }

  func toGuidePage(_ playerLocale: SupportLocale) {
    switch playerLocale {
    case is SupportLocale.Vietnam:
      NavigationManagement.sharedInstance.viewController.performSegue(
        withIdentifier: CryptoGuideVNDViewController.segueIdentifier,
        sender: nil)
    case is SupportLocale.China,
         is SupportLocale.Unknown:
      fallthrough
    default:
      NavigationManagement.sharedInstance.viewController.performSegue(
        withIdentifier: CryptoGuideViewController.segueIdentifier,
        sender: nil)
    }
  }
}
