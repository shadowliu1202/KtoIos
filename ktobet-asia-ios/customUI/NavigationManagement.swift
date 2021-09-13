import Foundation
import SideMenu
import SharedBu

let CUSTOM_NAVI_HEIGHT: CGFloat = 48.0
let DEFAULT_NAVI_HEIGHT: CGFloat = 44.0
let DIFF_NAVI_HEIGHT = CUSTOM_NAVI_HEIGHT - DEFAULT_NAVI_HEIGHT

class NavigationManagement {
    static let sharedInstance = NavigationManagement()
    
    private var sideBarViewController: SideBarViewController!
    private var menu: SideMenuNavigationController!
    
    var viewController: UIViewController!
    
    private init() { }
    
    func addMenuToBarButtonItem(vc: UIViewController, title: String? = nil) {
        viewController = vc
        if sideBarViewController == nil {
            initSideMenu()
        }
        
        SideMenuManager.default.addPanGestureToPresent(toView: vc.navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: vc.view, forMenu: .left)
        let menuButton = UIBarButtonItem(image: UIImage(named: "Menu")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.showMenu))
        addLeftBarButtonItems(leftBarButtonItems: [menuButton])
        vc.navigationItem.title = title
    }
    
    func addBarButtonItem(vc: UIViewController, barItemType: BarItemType) {
        viewController = vc
        addLeftBarButtonItems(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType)])
    }
    
    func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, title: String?) {
        addBarButtonItem(vc: vc, barItemType: barItemType)
        viewController.navigationItem.title = title
    }
    
    func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, leftItemTitle: String) {
        self.viewController = vc
        let titleItem = createTitleItem(title: leftItemTitle)
        addLeftBarButtonItems(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType), titleItem])
    }
    
    func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, image: String) {
        self.viewController = vc
        addLeftBarButtonItems(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType, image: image)])
    }

    func addBarButtonItem(vc: UIViewController, barItemType: BarItemType, action: Selector?) {
        self.viewController = vc
        addLeftBarButtonItems(leftBarButtonItems: [getBarButtonItem(barItemType: barItemType, action: action)])
    }
    
    @objc func back() {
        self.popViewController()
    }
    
    @objc func close() {
        self.popToRootViewController()
    }
    
    @objc func showMenu() {
        viewController.present(menu, animated: true, completion: nil)
    }
    
    func goTo(storyboard name: String, viewControllerId: String) {
        if name == "Login" && viewControllerId == "LoginNavigation" {
            dispose()
        }

        if menu != nil {
            menu.dismiss(animated: true, completion: nil)
        }
        
        viewController = UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: viewControllerId)
        UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController = self.viewController
    }
    
    func goTo(productType: ProductType?) {
        guard let productType = productType else {
            goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
            return
        }
        
        switch productType {
        case .sbk:
            goTo(storyboard: "Game", viewControllerId: "SBKNavigationController")
        case .numbergame:
            goTo(storyboard: "NumberGame", viewControllerId: "NumberGameNavigationController")
        case .casino:
            goTo(storyboard: "Casino", viewControllerId: "CasinoNavigationController")
        case .slot:
            goTo(storyboard: "Slot", viewControllerId: "SlotNavigationController")
        case .p2p:
            goTo(storyboard: "P2P", viewControllerId: "P2PNavigationController")
        case .arcade:
            goTo(storyboard: "Arcade", viewControllerId: "ArcadeNavigationController")
        default:
            goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
        }
    }
    
    func goTo(storyboard name: String, viewControllerId: String) {
        if name == "Login" && viewControllerId == "LoginNavigation" {
            dispose()
        }
        
        if menu != nil {
            menu.dismiss(animated: true, completion: nil)
        }
        
        viewController = UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: viewControllerId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController = self.viewController
        }
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
    
    private func initSideMenu() {
        sideBarViewController = UIStoryboard(name: "slideMenu", bundle: nil).instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideBarViewController
        menu = SideMenuNavigationController(rootViewController: sideBarViewController)
        var settings = SideMenuSettings()
        settings.presentationStyle = .menuSlideIn
        menu.settings = settings
        menu.menuWidth = viewController.view.bounds.width
        SideMenuManager.default.leftMenuNavigationController = menu
        sideBarViewController.observeSystemMessage()
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
        }
    }
    
    private func createTitleItem(title: String) -> UIBarButtonItem {
        let titleItem = UIBarButtonItem(title: title, style: .plain, target: self, action: nil)
        titleItem.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16.0)!], for: .normal)
        titleItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .normal)
        return titleItem
    }
    
    private func addLeftBarButtonItems(leftBarButtonItems: [UIBarButtonItem]) {
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let items = [negativeSeperator] + leftBarButtonItems
        viewController.navigationItem.leftBarButtonItems = items
        viewController.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    private func dispose() {
        guard let sideBar = sideBarViewController else { return }
        NotificationCenter.default.removeObserver(sideBar, name: NSNotification.Name(rawValue: "disposeSystemNotify"), object: nil)
        sideBarViewController = nil
        menu = nil
        UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController = nil
        SideMenuManager.default.leftMenuNavigationController = nil
    }
}

enum BarItemType {
    case back
    case close
}
