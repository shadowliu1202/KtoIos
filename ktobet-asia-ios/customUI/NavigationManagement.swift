import Foundation
import SideMenu

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
        }
        
        var settings = SideMenuSettings()
        settings.presentationStyle = .menuSlideIn
        menu.settings = settings
        menu.menuWidth = vc.view.bounds.width
        SideMenuManager.default.leftMenuNavigationController = menu
        SideMenuManager.default.addPanGestureToPresent(toView: vc.navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: vc.view, forMenu: .left)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.showMenu))
    }
    
    @objc func showMenu() {
        viewController.present(menu, animated: true, completion: nil)
    }
    
    func goTo(storyboard name: String, viewControllerId: String){
        if name == "Login" && viewControllerId == "LoginNavigation" {
            clean()
        }
        
        if !viewControllers.keys.contains(viewControllerId) {
            viewControllers[viewControllerId] =  UIStoryboard(name: name, bundle: nil).instantiateViewController(withIdentifier: viewControllerId)
        }
        
        if UIApplication.shared.keyWindow?.rootViewController == viewControllers[viewControllerId] {
            menu.dismiss(animated: true, completion: nil)
        }
        
        viewController = viewControllers[viewControllerId]
        UIApplication.shared.keyWindow?.rootViewController = viewControllers[viewControllerId]
    }
    
    private func clean() {
        viewControllers = [:]
    }
}
