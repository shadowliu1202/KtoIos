import Foundation
import SideMenu
import SharedBu

let CUSTOM_NAVI_HEIGHT: CGFloat = 48.0
let DEFAULT_NAVI_HEIGHT: CGFloat = 44.0
let DIFF_NAVI_HEIGHT = CUSTOM_NAVI_HEIGHT - DEFAULT_NAVI_HEIGHT

class NavigationManagement {
    private var sideBarViewController: SideBarViewController!
    private var menu: SideMenuNavigationController!

    static let sharedInstance = NavigationManagement()
    var viewController: UIViewController!
    var isShowAlert = false
    var closeAction: (() -> ())?
    var backAction: (() -> ())?
    var backTitle: String?
    var backMessage: String?
    var closeTitle: String?
    var closeMessage: String?
    private init() { }
    
    func addMenuToBarButtonItem(vc: UIViewController, title: String? = nil) {
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
        vc.navigationItem.title = title
        vc.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    func addBackToBarButtonItem(vc: UIViewController, isShowAlert: Bool = false, backTitle: String = Localize.string("common_tip_title_unfinished"), backMessage: String = Localize.string("common_tip_content_unfinished"), title: String? = nil, image: String = "Back", _ backAction: (() -> Void)? = nil) {
        self.isShowAlert = isShowAlert
        self.backTitle = backTitle
        self.backMessage = backMessage
        self.backAction = backAction
        viewController = vc
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let backButton = UIBarButtonItem(image: UIImage(named: image)?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.back))
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, backButton]
        vc.navigationItem.title = title
        vc.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    func addCloseToBarButtonItem(vc: UIViewController, isShowAlert: Bool = true, closeAction: (() -> ())? = nil, closeTitle: String = Localize.string("common_tip_title_unfinished"), closeMessage: String = Localize.string("common_tip_content_unfinished")) {
        self.isShowAlert = isShowAlert
        self.closeAction = closeAction
        self.closeTitle = closeTitle
        self.closeMessage = closeMessage
        self.viewController = vc
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let backButton = UIBarButtonItem(image: UIImage(named: "Close")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(NavigationManagement.close))
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, backButton]
        vc.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    func addBarButtonItem(vc: UIViewController, icon: BarButtonItem.ItemIcon, action: BarButtonItem.ItemAction) {
        self.viewController = vc
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let backButton = UIBarButtonItem(image: icon.icon?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: action.action)
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, backButton]
        vc.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    func addBarButtonItem(vc: UIViewController, icon: BarButtonItem.ItemIcon, customAction: Selector) {
        self.viewController = vc
        let negativeSeperator = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSeperator.width = 8
        let backButton = UIBarButtonItem(image: icon.icon?.withRenderingMode(.alwaysOriginal), style: .plain, target: vc, action: customAction)
        vc.navigationItem.leftBarButtonItems = [negativeSeperator, backButton]
        vc.additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    }
    
    enum BarButtonItem {
        enum ItemIcon {
            case back
            case close
            var icon: UIImage? {
                switch self {
                case .back:
                    return UIImage(named: "Back")
                case .close:
                    return UIImage(named: "Close")
                }
            }
        }
        enum ItemAction {
            case back
            case close
            var action: Selector {
                switch self {
                case .back:
                    return #selector(NavigationManagement.back)
                case .close:
                    return #selector(NavigationManagement.close)
                }
            }
        }
    }
    
    @objc func back() {
        var action: (() -> ())?
        if backAction != nil {
            action = backAction
        } else {
            action = {
                self.viewController.navigationController?.popViewController(animated: true)
                self.viewController = self.viewController.navigationController?.topViewController
            }
        }
        
        if self.isShowAlert {
            Alert.show(self.backTitle, self.backMessage) {
                action?()
            } cancel: {}
        } else {
            action?()
        }
    }
    
    @objc func close() {
        if self.isShowAlert {
            Alert.show(closeTitle, closeMessage) {
                self.viewController.navigationController?.popToRootViewController(animated: true)
                self.viewController = self.viewController.navigationController?.topViewController
            } cancel: {}
        } else {
            if self.closeAction != nil {
                self.closeAction?()
                self.viewController = self.viewController.navigationController?.topViewController
            } else {
                self.viewController.navigationController?.popToRootViewController(animated: true)
                self.viewController = self.viewController.navigationController?.topViewController
            }
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController = self.viewController
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
            goTo(storyboard: "NumberGame", viewControllerId: "NumberGameNavigationController")
        case .casino:
            goTo(storyboard: "Casino", viewControllerId: "CasinoNavigationController")
        case .slot:
            goTo(storyboard: "Slot", viewControllerId: "SlotNavigationController")
        case .p2p:
            goTo(storyboard: "P2P", viewControllerId: "P2PNavigationController")
        default:
            goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
        }
    }
    
    func popViewController(_ completion: (() -> Void)? = nil) {
        viewController.navigationController?.popViewController(animated: true)
        viewController = viewController.navigationController?.topViewController
        completion?()
    }
    
    func popViewController(_ completion: (() -> Void)? = nil, vc: UIViewController) {
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
    
    private func dispose() {
        guard let sideBar = sideBarViewController else { return }
        NotificationCenter.default.removeObserver(sideBar, name: NSNotification.Name(rawValue: "disposeSystemNotify"), object: nil)
        sideBarViewController = nil
        menu = nil
        UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController = nil
        SideMenuManager.default.leftMenuNavigationController = nil
    }
}
