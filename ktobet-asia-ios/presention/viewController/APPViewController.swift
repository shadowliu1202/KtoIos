import UIKit
import SwiftUI
import RxSwift
import NotificationBannerSwift

func methodPointer<T: AnyObject>(obj: T, method: @escaping (T) -> () -> Void) -> (() -> Void) {
    return { [unowned obj] in method(obj)() }
}

class APPViewController: UIViewController {
    private var banner: NotificationBanner?
    
    private let _errors = PublishSubject<Error>.init()
    private var errorsDispose: Disposable?
    let networkConnectRelay = BehaviorRelay<Bool>(value: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observerRequestError()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Reachability?.isNetworkConnected == true {
            self.networkReConnectedHandler()
        } else {
            self.networkDisconnectHandler()
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
    
    func networkReConnectedHandler() {
        dismissBanner()
    }
    
    func networkDisconnectHandler() {
        displayBanner()
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
        self.networkReConnectedHandler()
        self.networkConnectRelay.accept(true)
    }
    
    func networkDisConnected() {
        self.networkDisconnectHandler()
        self.networkConnectRelay.accept(false)
    }
    
    func networkRequestHandle(error: Error) {
        _errors.onNext(error)
    }
}

