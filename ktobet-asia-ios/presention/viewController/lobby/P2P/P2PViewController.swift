import AlignedCollectionViewFlowLayout
import RxCocoa
import RxSwift
import SDWebImage
import SharedBu
import UIKit

class P2PViewController: ProductsViewController {
  @IBOutlet weak var tableView: UITableView!

  @Injected private(set) var viewModel: P2PViewModel

  private var disposeBag = DisposeBag()

  var barButtonItems: [UIBarButtonItem] = []

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    Logger.shared.info("\(type(of: self)) viewDidLoad.")

    setupUI()
    binding()
  }

  override func setProductType() -> ProductType {
    .p2p
  }

  override func handleErrors(_ error: Error) {
    if error.isMaintenance() {
      NavigationManagement.sharedInstance.goTo(productType: .p2p, isMaintenance: true)
    }
    else {
      super.handleErrors(error)
    }
  }
}

// MARK: - UI

extension P2PViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    bind(position: .right, barButtonItems: .kto(.record))

    tableView.estimatedRowHeight = 208.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
  }

  private func binding() {
    viewModel.dataSource
      .bind(to: tableView.rx.items) { tableView, row, item in
        let cell: P2PTableViewCell = tableView.dequeueReusableCell(forIndexPath: [0, row])

        if let url = URL(string: item.thumbnail.url()) {
          cell.iconImageView.sd_setImage(url: url)
          cell.iconImageView.borderWidth = 1
          cell.iconImageView.bordersColor = .grayC8D4DE.withAlphaComponent(0.8)
        }

        cell.label.text = item.gameName
        return cell
      }
      .disposed(by: disposeBag)

    bindWebGameResult(with: viewModel)

    viewModel.errorsSubject
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)

    tableView.rx
      .modelSelected(P2PGame.self)
      .bind { [unowned self] data in
        self.viewModel.fetchGame(data)
      }
      .disposed(by: disposeBag)
  }
}

// MARK: - BarButtonItemable

extension P2PViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    guard sender is RecordBarButtonItem else { return }

    let betSummaryViewController = P2PSummaryViewController.initFrom(storyboard: "P2P")
    navigationController?.pushViewController(betSummaryViewController, animated: true)
  }
}
