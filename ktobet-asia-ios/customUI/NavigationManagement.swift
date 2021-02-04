import Foundation
import SideMenu
import share_bu

class NavigationManagement {
    private var sideBarViewController: SideBarViewController!
    private var menu: SideMenuNavigationController!
    private var viewController: UIViewController!
    private var viewControllers: [String: UIViewController] = [:]

    static let sharedInstance = NavigationManagement()
    
    private init() { }
    
    func addMenuToBarButtonItem(vc: UIViewController) {
        viewController = vc
        if sideBarViewController == nil {
            sideBarViewController = UIStoryboard(name: "slideMenu", bundle: nil).instantiateViewController(withIdentifier: "LeftMenuNavigationController") as? SideBarViewController
            menu = SideMenuNavigationController(rootViewController: sideBarViewController)
            var settings = SideMenuSettings()
            settings.presentationStyle = .menuSlideIn
            menu.settings = settings
            menu.menuWidth = vc.view.bounds.width
            SideMenuManager.default.leftMenuNavigationController = menu
            sideBarViewController.observeSystemMessage()
        }
        
        SideMenuManager.default.addPanGestureToPresent(toView: vc.navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: vc.view, forMenu: .left)
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let menuButton = UIBarButtonItem(image: UIImage(named: "Menu")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.showMenu))
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, menuButton]
    }
    
    func addBackToBarButtonItem(vc: UIViewController) {
        viewController = vc
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let backButton = UIBarButtonItem(image: UIImage(named: "Back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.back))
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, backButton]
    }
    
    @objc func back() {
        viewController.navigationController?.popViewController(animated: true)
    }
    
    @objc func showMenu() {
        viewController.present(menu, animated: true, completion: nil)
    }
    
    func goTo(storyboard name: String, viewControllerId: String) {
        if name == "Login" && viewControllerId == "LoginNavigation" {
            dispose()
        }
        
        if !viewControllers.keys.contains(viewControllerId) {
            viewControllers[viewControllerId] =  UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: viewControllerId)
        }

        if menu != nil {
            menu.dismiss(animated: true, completion: nil)
        }
        
        viewController = viewControllers[viewControllerId]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.keyWindow?.rootViewController = self.viewControllers[viewControllerId]
        }
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
            goTo(storyboard: "Game", viewControllerId: "NumberGameNavigationController")
        case .casino:
            goTo(storyboard: "Game", viewControllerId: "CasinoNavigationController")
        case .slot:
            goTo(storyboard: "Game", viewControllerId: "SlotNavigationController")
        default:
            goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
        }
    }
    
    private func dispose() {
        guard let sideBar = sideBarViewController else { return }
        NotificationCenter.default.removeObserver(sideBar, name: NSNotification.Name(rawValue: "disposeSystemNotify"), object: nil)
        viewControllers = [:]
        sideBarViewController = nil
        menu = nil
    }
}
