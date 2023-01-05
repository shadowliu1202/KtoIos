import UIKit
import RxSwift
import SharedBu

class ProductsViewController: LobbyViewController {
    private var disposeBag = DisposeBag()
    private lazy var serviceViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
    private lazy var playerViewModel = Injectable.resolve(PlayerViewModel.self)!
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
        serviceViewModel.output.portalMaintenanceStatus
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case is MaintenanceStatus.AllPortal:
                    self.playerViewModel.logout()
                        .subscribe(onCompleted: {
                            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
                        })
                        .disposed(by: self.disposeBag)
                    
                case let productStatus as MaintenanceStatus.Product:
                    if productStatus.isProductMaintain(productType: self.productType) {
                        NavigationManagement.sharedInstance.goTo(productType: self.productType, isMaintenance: true)
                    }
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
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
    
    func handleBonusStatusAlert(_ status: WebGameBonusStatus?) {
        switch status {
        case .bonusCalculating(let gameName):
            Alert.shared.show(
                Localize.string("common_tip_title_warm"),
                String(format: Localize.string("product_bonus_calculating"), gameName),
                confirm: {},
                cancel: nil
            )
            
        case .lockedBonus(let gameName, let turnOverDetail):
            present(
                TurnoverAlertViewController(gameName: gameName, turnover: turnOverDetail),
                animated: true
            )
            
        default:
            break
        }
    }
    
    override func handleErrors(_ error: Error) {
        switch error {
        case is KtoGameUnderMaintenance:
            Alert.shared.show(
                nil,
                Localize.string("product_game_maintenance"),
                confirm: {},
                cancel: nil
            )
        default:
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
