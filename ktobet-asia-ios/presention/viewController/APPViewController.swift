import UIKit
import SwiftUI
import RxSwift
import NotificationBannerSwift

func methodPointer<T: AnyObject>(obj: T, method: @escaping (T) -> () -> Void) -> (() -> Void) {
    return { [unowned obj] in method(obj)() }
}

class APPViewController: UIViewController {
    private var networkDisconnectHandler: (() -> ())?
    private var networkReConnectedHandler: (() -> ())?
    private var banner: NotificationBanner?
    
    private let _errors = PublishSubject<Error>.init()
    private var errorsDispose: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkNetworkDisConnectHandler()
        checkNetworkReConnectHandler()
        observerRequestError()
    }
    
    private func checkNetworkDisConnectHandler() {
        if let custom = registerNetworkDisConnnectedHandler() {
            self.networkDisconnectHandler = custom
        } else {
            let displayBanner = methodPointer(obj: self, method: APPViewController.displayBanner)
            self.networkDisconnectHandler = displayBanner
        }
    }
    
    private func checkNetworkReConnectHandler() {
        if let custom = registerNetworkReConnectedHandler() {
            self.networkReConnectedHandler = custom
        } else {
            let dismissBanner = methodPointer(obj: self, method: APPViewController.dismissBanner)
            self.networkReConnectedHandler = dismissBanner
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Reachability?.isNetworkConnected == true {
            self.networkReConnectedHandler?()
        } else {
            self.networkDisconnectHandler?()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        errorsDispose?.dispose()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.dismissBanner()
    }
    
    func registerViewDidLoadNetworkHandler() -> (() -> ())? {
        return nil
    }
    
    func registerNetworkDisConnnectedHandler() -> (() -> ())? {
        return nil
    }
    
    func registerNetworkReConnectedHandler() -> (() -> ())? {
        return nil
    }
    
    private func displayBanner() {
        guard !(banner?.isDisplaying ?? false) else { return }
        let view = UIHostingController(rootView: BannerView()).view
        view?.backgroundColor = .clear
        let bannerQueue5AllowedMixed = NotificationBannerQueue(maxBannersOnScreenSimultaneously: Int.max)
        banner = NotificationBanner(customView: view!)
        banner?.autoDismiss = false
        banner?.show(queue: bannerQueue5AllowedMixed, on: self)
    }
    
    private func dismissBanner() {
        banner?.dismiss()
    }
    
    private func observerRequestError() {
        errorsDispose = _errors.throttle(.milliseconds(1500), latest: false, scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
    }

}

extension APPViewController: NetworkStatusDisplay {
    func networkDidConnected() {
        self.networkReConnectedHandler?()
    }
    
    func networkDisConnected() {
        self.networkDisconnectHandler?()
    }
    
    func networkRequestHandle(error: Error) {
        _errors.onNext(error)
    }
}

