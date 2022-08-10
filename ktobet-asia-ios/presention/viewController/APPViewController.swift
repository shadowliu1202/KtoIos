import UIKit
import SwiftUI
import RxSwift

func methodPointer<T: AnyObject>(obj: T, method: @escaping (T) -> () -> Void) -> (() -> Void) {
    return { [unowned obj] in method(obj)() }
}

class APPViewController: UIViewController {
    private var banner: UIView?

    private let _errors = PublishSubject<Error>.init()
    private var errorsDispose: Disposable?
    let networkConnectRelay = BehaviorRelay<Bool>(value: true)
    var versionSyncDisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        observerRequestError()
        initNetworkConnectRelay()
    }

    private func initNetworkConnectRelay() {
        networkConnectRelay.accept(NetworkStateMonitor.shared.isNetworkConnected)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if NetworkStateMonitor.shared.isNetworkConnected == true {
            self.networkReConnectedHandler()
        } else {
            self.networkDisconnectHandler()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        errorsDispose?.dispose()
        versionSyncDisposeBag = DisposeBag()
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
        guard banner == nil else { return }
        banner = UIHostingController(rootView: BannerView()).view
        banner?.backgroundColor = .clear
        self.view.addSubview(banner!, constraints: [
            .constraint(.equal, \.layoutMarginsGuide.topAnchor, offset: 0),
            .constraint(.equal, \.heightAnchor, length: 52),
            .equal(\.leadingAnchor, offset: 0),
            .equal(\.trailingAnchor, offset: -0)
        ])
    }

    private func dismissBanner() {
        banner?.removeFromSuperview()
        banner = nil
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

extension APPViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if NetworkStateMonitor.shared.isNetworkConnected == true {
            self.networkReConnectedHandler()
        } else {
            self.networkDisconnectHandler()
        }
    }
}
