import UIKit
import RxSwift
import SharedBu

class ProductsViewController: LobbyViewController {
    private var disposeBag = DisposeBag()
    private var viewDisappearBag = DisposeBag()
  
    private lazy var serviceViewModel = Injectable.resolveWrapper(ServiceStatusViewModel.self)
    private lazy var playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)
    private lazy var productsViewModel = Injectable.resolveWrapper(ProductsViewModel.self)
  
    private var productType: ProductType!
  
    override func viewDidLoad() {
       super.viewDidLoad()
       self.productType = setProductType()
      
        binding()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      productsViewModel.fetchMaintenanceStatus()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewDisappearBag = DisposeBag()
    }
    
    func setProductType() -> ProductType {
        fatalError("implements in sub class")
    }
    
    private func binding() {
      productsViewModel
        .observeMaintenanceStatus()
        .subscribe(onNext: { [weak self] status in
          guard let self else { return }

          switch status {
          case is MaintenanceStatus.AllPortal:
            self.playerViewModel.logout()
              .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(
                  storyboard: "Maintenance",
                  viewControllerId: "PortalMaintenanceViewController")
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
      
      productsViewModel.errors()
        .subscribe(onNext: { [weak self] error in
          guard let self else { return }
          
          self.handleErrors(error)
        })
        .disposed(by: disposeBag)
    }

    func gameDidDisappear() {
        syncAppVersionUpdate(viewDisappearBag)
        serviceViewModel.refreshProductStatus()
    }
    
    func bindWebGameResult(with viewModel: ProductWebGameViewModelProtocol) {
        viewModel
            .webGameResultDriver
            .drive(onNext: { [weak self] in
                self?.handleWebGameResult($0, with: viewModel)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleWebGameResult(_ result: WebGameResult, with viewModel: ProductWebGameViewModelProtocol) {
        switch result {
        case .loaded(let gameName, let url):
            let storyboard = UIStoryboard(name: "Product", bundle: nil)
            guard let navigation = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as? UINavigationController,
                  let web = navigation.viewControllers.first as? GameWebViewViewController
            else {
                return
            }
            
            web.gameUrl = url
            web.gameName = gameName
            web.viewModel = viewModel
            web.delegate = self
            navigation.modalPresentationStyle = .overFullScreen
            present(navigation, animated: true)
            
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
            
        case .inactive:
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
