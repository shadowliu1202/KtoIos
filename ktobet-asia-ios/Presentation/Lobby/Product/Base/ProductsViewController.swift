import RxSwift
import SharedBu
import UIKit

class ProductsViewController: LobbyViewController {
  @Injected private var loading: Loading
  @Injected private var alert: AlertProtocol
  @Injected private var productsViewModel: ProductsViewModel

  private var disposeBag = DisposeBag()
  private var viewDisappearBag = DisposeBag()

  private var productType: ProductType!

  private var placeholder: LoadingPlaceholderViewController?
  
  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.productType = setProductType()

    binding()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewDisappearBag = DisposeBag()
  }

  func setProductType() -> ProductType {
    fatalError("implements in sub class")
  }

  private func binding() {
    productsViewModel.maintenanceStatus
      .drive(onNext: { [weak self, productsViewModel] status in
        guard let self else { return }

        switch status {
        case is MaintenanceStatus.AllPortal:
          productsViewModel.logout()
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
    productsViewModel.refreshMaintenanceStatus()
  }

  func bindWebGameResult(with viewModel: ProductWebGameViewModelProtocol) {
    viewModel
      .webGameResultDriver
      .drive(onNext: { [weak self] in
        self?.handleWebGameResult($0, with: viewModel)
      })
      .disposed(by: disposeBag)
  }

  func bindPlaceholder(
    _ type: LoadingPlaceholder.`Type`,
    with viewModel: ProductWebGameViewModelProtocol)
  {
    placeholder = .init(type)

    guard let placeholder else { return }

    loading
      .bindPlaceholder(
        placeholder,
        to: viewModel.placeholderTracker.asObservable(),
        at: self)
      .disposed(by: disposeBag)
  }

  private func handleWebGameResult(_ result: WebGameResult, with viewModel: ProductWebGameViewModelProtocol) {
    switch result {
    case .loaded(let gameName, let url):
      let storyboard = UIStoryboard(name: "Product", bundle: nil)
      guard
        let navigation = storyboard
          .instantiateViewController(withIdentifier: "GameNavigationViewController") as? UINavigationController,
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
        confirm: { },
        cancel: nil)

    case .lockedBonus(let gameName, let turnOverDetail):
      present(
        TurnoverAlertViewController(situation: .intoGame(gameName: gameName), turnover: turnOverDetail),
        animated: true)

    case .inactive:
      break
    }
  }

  override func handleErrors(_ error: Error) {
    switch error {
    case is KtoGameUnderMaintenance:
      alert.show(
        nil,
        Localize.string("product_game_maintenance"),
        confirm: { },
        cancel: nil)
    case is GameFavoriteReachMaxLimit:
      alert.show(
        Localize.string("common_error"),
        Localize.string("product_favorite_reach_max"),
        confirm: { },
        cancel: nil)
    default:
      super.handleErrors(error)
    }
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension ProductsViewController: WebGameViewCallback {
  func gameDisappear() {
    self.gameDidDisappear()
  }
}
