import UIKit
import RxSwift
import SharedBu

class AppVersionCheckViewController: APPViewController {
    private var disposeBag: DisposeBag!
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private let playerViewModel = DI.resolve(PlayerViewModel.self)!
    private let appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    private var productType: ProductType?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disposeBag = DisposeBag()
        observeUpdateVersion()
        observeSystemStatus()
        registerAppEnterForeground()
    }
    
    func registerAppEnterForeground() {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).takeUntil(self.rx.deallocated).subscribe(onNext: { [weak self] _ in
            self?.observeUpdateVersion()
        }).disposed(by: disposeBag)
    }
    
    func observeUpdateVersion() {
        guard Configuration.isAutoUpdate else { return }
        appSyncViewModel.getLatestAppVersion().map({ Bundle.main.currentVersion.getUpdateAction(latestVersion: $0) })
            .subscribe(onSuccess: { [weak self] in
                if $0 == .compulsoryupdate {
                    self?.executeLogout()
                }
            }).disposed(by: disposeBag)
    }
    
    private func executeLogout() {
        playerViewModel.logout().subscribeOn(MainScheduler.instance).subscribe(onCompleted: { [weak self] in
            self?.disposeBag = DisposeBag()
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }, onError: {
            print($0)
        }).disposed(by: disposeBag)
    }
    
    private func observeSystemStatus() {
        serviceViewModel.output.portalMaintenanceStatus.drive(onNext: { [weak self] status in
            guard let self = self, let productType = self.productType else { return }
            switch status {
            case is MaintenanceStatus.AllPortal:
                self.playerViewModel.logout()
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onCompleted: { [weak self] in
                        self?.showLoginMaintenanAlert()
                    }).disposed(by: self.disposeBag)
            case let productStatus as MaintenanceStatus.Product:
                if productStatus.isProductMaintain(productType: productType) {
                    NavigationManagement.sharedInstance.goTo(productType: productType, isMaintenance: true)
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }
    
    func gameDidDisappear() {
        if Reachability?.isNetworkConnected == false {
            self.networkDisConnected()
        }
        observeUpdateVersion()
        serviceViewModel.refreshProductStatus()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension AppVersionCheckViewController: WebGameViewCallback {
    func gameDidDisappear(productType: ProductType?) {
        self.productType = productType
        self.gameDidDisappear()
    }
}
