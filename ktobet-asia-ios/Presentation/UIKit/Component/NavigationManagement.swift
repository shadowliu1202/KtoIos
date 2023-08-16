import Foundation
import SharedBu
import SideMenu
import UIKit

let CUSTOM_NAVI_HEIGHT: CGFloat = 48.0
let DEFAULT_NAVI_HEIGHT: CGFloat = 44.0
let DIFF_NAVI_HEIGHT = CUSTOM_NAVI_HEIGHT - DEFAULT_NAVI_HEIGHT

protocol Navigator {
  var sideBarViewController: SideBarViewController! { get set }
  var menu: SideMenuNavigationController! { get set }

  var viewController: UIViewController! { get set }
  var previousRootViewController: UIViewController? { get set }
  var unwindNavigate: NotificationNavigate? { get set }

  func addMenuToBarButtonItem(vc: UIViewController, title: String?)
  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, title: String?)
  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, leftItemTitle: String)
  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String?, action: Selector?)
  func addRightBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String?, action: Selector?)

  func goTo(storyboard name: String, viewControllerId: String)
  func goToPreviousRootViewController()
  func goToSetDefaultProduct()
  func goTo(productType: ProductType, isMaintenance: Bool)

  func popViewController(_ completion: (() -> Void)?)
  func popViewController(_ completion: (() -> Void)?, to vc: UIViewController)
  func popToRootViewController(_ completion: (() -> Void)?)
  func popToNotificationOrBack(unwind: () -> Void)

  func navigateToAuthorization()

  func pushViewController(vc: UIViewController)
  func pushViewController(vc: UIViewController, unwindNavigate: NotificationNavigate?)

  func back()
}

extension Navigator {
  func addMenuToBarButtonItem(vc: UIViewController, title: String? = nil) {
    addMenuToBarButtonItem(vc: vc, title: title)
  }

  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, title: String? = nil) {
    addBarButtonItem(vc: vc, barItemType: barItemType, title: title)
  }

  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String? = nil, action: Selector? = nil) {
    addBarButtonItem(vc: vc, barItemType: barItemType, image: image, action: action)
  }

  func addRightBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String? = nil, action: Selector? = nil) {
    addRightBarButtonItem(vc: vc, barItemType: barItemType, image: image, action: action)
  }

  func goTo(productType: ProductType, isMaintenance: Bool = false) {
    goTo(productType: productType, isMaintenance: isMaintenance)
  }

  func popToRootViewController(_ completion: (() -> Void)? = nil) {
    popToRootViewController(completion)
  }

  func popViewController(_ completion: (() -> Void)? = nil, to vc: UIViewController) {
    popViewController(completion, to: vc)
  }

  func popViewController(_ completion: (() -> Void)? = nil) {
    popViewController(completion)
  }
}

enum BarItemType {
  case back
  case close
  case none
}

class NavigationManagement: Navigator {
  static var sharedInstance: Navigator = NavigationManagement()

  var sideBarViewController: SideBarViewController!
  var menu: SideMenuNavigationController!

  var viewController: UIViewController!
  var previousRootViewController: UIViewController?
  weak var unwindNavigate: NotificationNavigate?

  private init() { }

  func addMenuToBarButtonItem(vc: UIViewController, title: String? = nil) {
    guard let navigationBar = vc.navigationController?.navigationBar else { return }

    viewController = vc

    if sideBarViewController == nil {
      initSideMenu()
    }

    SideMenuManager.default.addPanGestureToPresent(toView: navigationBar)
    SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: vc.view, forMenu: .left)

    let menuButton = UIBarButtonItem(
      image: UIImage(named: "Menu")?.withRenderingMode(.alwaysOriginal),
      style: .plain,
      target: self,
      action: #selector(NavigationManagement.showMenu))

    add(leftBarButtonItems: [menuButton])

    vc.navigationItem.title = title
    updateNavigationTitleOniOS16()
  }

  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, title: String? = nil) {
    viewController = vc
    add(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType)])
    viewController.navigationItem.title = title
    updateNavigationTitleOniOS16()
  }

  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, leftItemTitle: String) {
    self.viewController = vc
    let titleItem = createTitleItem(title: leftItemTitle)
    add(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType), titleItem])
  }

  func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String? = nil, action: Selector? = nil) {
    self.viewController = vc
    add(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType, action: action, image: image)])
  }

  func addRightBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String? = nil, action: Selector? = nil) {
    self.viewController = vc
    add(rightBarButtonItems: [getBarButtonItem(barItemType: barItemType, action: action, image: image)])
  }

  @objc
  func back() {
    self.popViewController()
  }

  @objc
  func close() {
    self.popToRootViewController()
  }

  @objc
  func showMenu() {
    viewController.present(menu, animated: true, completion: nil)
  }

  func goTo(storyboard name: String, viewControllerId: String) {
    if
      viewControllerId == "LandingNavigation" || viewControllerId == "LaunchViewController" || viewControllerId ==
      "PortalMaintenanceViewController"
    {
      dispose()
    }

    if menu != nil {
      menu.dismiss(animated: true, completion: {
        self.setRootViewController(storyboard: name, viewControllerId: viewControllerId)
      })

      return
    }

    setRootViewController(storyboard: name, viewControllerId: viewControllerId)
  }

  func goToPreviousRootViewController() {
    if let previous = previousRootViewController {
      self.viewController = previous
      UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController = previousRootViewController
    }
  }

  func goToSetDefaultProduct() {
    goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
  }

  func goTo(productType: ProductType, isMaintenance: Bool = false) {
    let storyboard = isMaintenance ? "Maintenance" : productType.name
    let viewControllerId = isMaintenance ? productType.name + "Maintenance" : productType.name + "NavigationController"
    goTo(storyboard: storyboard, viewControllerId: viewControllerId)
  }

  func popViewController(_ completion: (() -> Void)? = nil) {
    viewController.navigationController?.popViewController(animated: true)
    viewController = viewController.navigationController?.topViewController
    completion?()
  }

  func popViewController(_ completion: (() -> Void)? = nil, to vc: UIViewController) {
    viewController.navigationController?.popToViewController(vc, animated: true)
    viewController = viewController.navigationController?.topViewController
    completion?()
  }

  func popToRootViewController(_ completion: (() -> Void)? = nil) {
    self.viewController.navigationController?.popToRootViewController(animated: true)
    self.viewController = self.viewController.navigationController?.topViewController
    completion?()
  }

  func pushViewController(vc: UIViewController) {
    viewController.navigationController?.pushViewController(vc, animated: true)
    viewController = viewController.navigationController?.topViewController
  }

  func pushViewController(vc: UIViewController, unwindNavigate: NotificationNavigate?) {
    viewController.navigationController?.pushViewController(vc, animated: true)
    viewController = viewController.navigationController?.topViewController
    self.unwindNavigate = unwindNavigate
  }

  func navigateToAuthorization() {
    sideBarViewController.navigationController?.dismiss(animated: true, completion: nil)

    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
    let navi = storyboard
      .instantiateViewController(withIdentifier: "AuthProfileModificationNavigation") as! UINavigationController
    navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
    let vc = navi.viewControllers.first as? AuthProfileModificationViewController
    vc?.didAuthenticated = { [weak self] in
      self?.sideBarViewController.cleanProductSelected()
    }
    if let currentVC = viewController as? UIAdaptivePresentationControllerDelegate {
      vc?.presentationController?.delegate = currentVC
    }

    viewController.present(navi, animated: true, completion: nil)
  }

  func popToNotificationOrBack(unwind: () -> Void) {
    if let navi = self.unwindNavigate {
      let callback = {
        self.unwindNavigate = nil
      }
      self.popViewController(callback, to: navi)
    }
    else {
      unwind()
    }
  }

  private func setRootViewController(storyboard name: String, viewControllerId: String) {
    self.viewController = UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: viewControllerId)
    UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController = self.viewController
  }

  private func initSideMenu() {
    sideBarViewController = UIStoryboard(name: "slideMenu", bundle: nil)
      .instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideBarViewController
    menu = SideMenuNavigationController(rootViewController: sideBarViewController)
    var settings = SideMenuSettings()
    settings.presentationStyle = .menuSlideIn
    menu.settings = settings
    menu.menuWidth = viewController.view.bounds.width
    SideMenuManager.default.leftMenuNavigationController = menu

    sideBarViewController.observeKickOutSignal()
  }

  private func getBarButtonItem(barItemType: BarItemType, action: Selector? = nil, image: String? = nil) -> UIBarButtonItem {
    let button = UIBarButtonItem()
    button.style = .plain
    button.target = action == nil ? self : self.viewController
    switch barItemType {
    case .back:
      button.image = (UIImage(named: image ?? "") ?? UIImage(named: "Back"))?.withRenderingMode(.alwaysOriginal)
      button.action = action ?? #selector(back)
      return button
    case .close:
      button.image = (UIImage(named: image ?? "") ?? UIImage(named: "Close"))?.withRenderingMode(.alwaysOriginal)
      button.action = action ?? #selector(close)
      return button
    case .none:
      return button
    }
  }

  private func createTitleItem(title: String) -> UIBarButtonItem {
    let titleItem = UIBarButtonItem(title: title, style: .plain, target: self, action: nil)
    titleItem.setTitleTextAttributes(
      [NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16.0)!],
      for: .normal)
    titleItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.greyScaleWhite], for: .normal)
    return titleItem
  }

  private func add(leftBarButtonItems: [UIBarButtonItem]) {
    let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    negativeSeperator.width = 8
    let items = [negativeSeperator] + leftBarButtonItems
    viewController.navigationItem.leftBarButtonItems = items
    viewController.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
  }

  private func add(rightBarButtonItems: [UIBarButtonItem]) {
    let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    negativeSeperator.width = 8
    let items = (viewController.navigationItem.rightBarButtonItems ?? []) + [negativeSeperator] + rightBarButtonItems
    viewController.navigationItem.rightBarButtonItems = items
    viewController.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
  }

  private func updateNavigationTitleOniOS16() {
    // FIXME: workaround iOS16 UINavigationBar title does not appear after being updated
    // https://developer.apple.com/forums/thread/713424
    if #available(iOS 16.0, *) {
      viewController.navigationController?.navigationBar.setNeedsLayout()
    }
  }

  private func dispose() {
    // FIXME: SideBarViewController retain cycle.
    // Manually release SideMenuViewModel to stop system massage socket connection.

    sideBarViewController?.deallocate()
    sideBarViewController = nil
    menu = nil
    UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController = nil
    SideMenuManager.default.leftMenuNavigationController = nil
  }
}
