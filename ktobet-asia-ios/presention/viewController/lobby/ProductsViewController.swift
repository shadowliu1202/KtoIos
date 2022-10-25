import UIKit
import RxSwift
import SharedBu

class ProductsViewController: LobbyViewController {
    private var disposeBag = DisposeBag()
    private lazy var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private lazy var playerViewModel = DI.resolve(PlayerViewModel.self)!
    private var productType: ProductType!
    override func viewDidLoad() {
       super.viewDidLoad()
       self.productType = setProductType()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeSystemStatus()
    }

    func setProductType() -> ProductType {
        fatalError("implements in sub class")
    }
    
    private func observeSystemStatus() {
        serviceViewModel.output.portalMaintenanceStatus.subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case is MaintenanceStatus.AllPortal:
                self.playerViewModel.logout()
                    .subscribe(on: MainScheduler.instance)
                    .subscribe(onCompleted: { [weak self] in
                        self?.showLoginMaintenanAlert()
                    }).disposed(by: self.disposeBag)
            case let productStatus as MaintenanceStatus.Product:
                if productStatus.isProductMaintain(productType: self.productType) {
                    NavigationManagement.sharedInstance.goTo(productType: self.productType, isMaintenance: true)
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

    func gameDidDisappear() {
        if NetworkStateMonitor.shared.isNetworkConnected == false {
            self.networkDisConnected()
        }
        syncAppVersionUpdate(versionSyncDisposeBag)
        serviceViewModel.refreshProductStatus()
    }
    
    func goToWebGame(viewModel: ProductWebGameViewModelProtocol, gameId: Int32, gameName: String) {
        viewModel.createGame(gameId: gameId).subscribe(on: MainScheduler.instance).subscribe { (url) in
            let storyboard = UIStoryboard(name: "Product", bundle: nil)
            let navi = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as! UINavigationController
            if let gameVc = navi.viewControllers.first as? GameWebViewViewController {
                gameVc.gameUrl = url
                gameVc.gameName = gameName
                gameVc.viewModel = viewModel
                gameVc.delegate = self
                navi.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                self.present(navi, animated: true, completion: nil)
            }
        } onFailure: { [weak self] in
            self?.handleErrors($0)
        }.disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoGameUnderMaintenance {
            Alert.shared.show(nil, Localize.string("product_game_maintenance"), confirm: {}, cancel: nil)
        } else {
            super.handleErrors(error)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension ProductsViewController: WebGameViewCallback {
    func gameDisappear() {
        self.gameDidDisappear()
    }
}
