import RxCocoa
import RxSwift
import sharedbu
import UIKit

class DefaultProductViewController: LobbyViewController {
  @IBOutlet private weak var btnIgnore: UIBarButtonItem!
  @IBOutlet private weak var btnInfo: UIButton!
  @IBOutlet private weak var labTitle: UILabel!
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var btnNext: UIButton!

  private let segueLobby = "BackToLobby"

  private let playerConfiguration = Injectable.resolve(PlayerConfiguration.self)!
  private let navigationViewModel = Injectable.resolve(NavigationViewModel.self)!

  private lazy var httpClient = Injectable.resolve(HttpClient.self)!
  private lazy var viewModel = Injectable.resolve(DefaultProductViewModel.self)!

  private var disposeBag = DisposeBag()
  private var games: [DefaultProductType] = [.sbk, .casino, .slot, .numberGame]
  private var currentSelectGame: DefaultProductType?

  // MARK: LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()
    defaultStyle()
  }

  // MARK: METHOD
  private func defaultStyle() {
    self.btnNext.layer.cornerRadius = 9
    self.btnNext.layer.masksToBounds = true
    btnNext.isValid = false
  }

  // MARK: BUTTON ACTION
  @IBAction
  func btnIgnorePressed(_: UIButton) {
    saveDefaultProductThenNavigation(.sbk)
  }

  @IBAction
  func btnNextPressed(_: UIButton) {
    guard let item = currentSelectGame else {
      return
    }
    saveDefaultProductThenNavigation(item)
  }

  private func saveDefaultProductThenNavigation(_ productType: DefaultProductType) {
    viewModel
      .setDefaultProduct(productType)
      .andThen(viewModel.getPortalMaintenanceState())
      .subscribe(onSuccess: { [unowned self] maintenanceStatus in
        switch onEnum(of: maintenanceStatus) {
        case .allPortal:
          navigateToPortalMaintenancePage()
        case .product:
          navigateToProductPage(productType)
        }
      }, onFailure: { error in
        self.handleErrors(error)
      }).disposed(by: disposeBag)
  }

  private func navigateToProductPage(_ productType: DefaultProductType) {
    let viewControllerId = productType.name + "NavigationController"
    NavigationManagement.sharedInstance.goTo(storyboard: productType.name, viewControllerId: viewControllerId)
  }
  
  private func navigateToPortalMaintenancePage() {
    Alert.shared.show(
      Localize.string("common_maintenance_notify"),
      Localize.string("common_maintenance_contact_later"),
      confirm: {
        NavigationManagement.sharedInstance.goTo(
          storyboard: "Maintenance",
          viewControllerId: "PortalMaintenanceViewController")
      },
      cancel: nil)
  }

  @IBAction
  func btnInfoPressed(_: UIButton) {
    let title = Localize.string("common_tip_title_warm")
    let message = Localize.string("profile_defaultproduct_description")
    Alert.shared.show(title, message, confirm: nil, cancel: nil)
  }
}

extension DefaultProductViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    btnNext.isValid = true
    currentSelectGame = games[indexPath.row]
    tableView.reloadData()
  }
}

extension DefaultProductViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    games.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = games[indexPath.row]
    let identifier = String(describing: DefaultProductCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! DefaultProductCell
    cell.setup(item, playerConfiguration.supportLocale, currentSelectGame, httpClient.host.absoluteString)
    return cell
  }

  func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    116
  }
}
