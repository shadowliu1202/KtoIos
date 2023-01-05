import UIKit
import RxSwift
import RxCocoa
import SharedBu
import AlignedCollectionViewFlowLayout
import SDWebImage

class P2PViewController: ProductsViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @Injected private (set) var viewModel: P2PViewModel
    
    private var disposeBag = DisposeBag()
    
    var barButtonItems: [UIBarButtonItem] = []
    
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
    
    private func checkTurnOver(p2pGame: P2PGame) {
        viewModel.getTurnOverStatus()
            .subscribe(onSuccess: { [unowned self] (turnOver) in
                switch turnOver {
                case is P2PTurnOver.Calculating:
                    Logger.shared.info("Calculating")
                    
                    Alert.shared.show(
                        Localize.string("common_tip_title_warm"),
                        Localize.string("product_p2p_bonus_calculating"),
                        confirm: {},
                        cancel: nil
                    )
                    
                case is P2PTurnOver.None:
                    self.goToWebGame(
                        viewModel: self.viewModel,
                        gameId: p2pGame.gameId,
                        gameName: p2pGame.gameName
                    )
                    
                case is P2PTurnOver.TurnOverReceipt:
                    let p2pAlertView = P2PAlertViewController.initFrom(storyboard: "P2P")
                    p2pAlertView.p2pTurnOver = turnOver
                    p2pAlertView.view.backgroundColor = .gray131313.withAlphaComponent(0.8)
                    p2pAlertView.modalPresentationStyle = .overCurrentContext
                    p2pAlertView.modalTransitionStyle = .crossDissolve
                    self.present(p2pAlertView, animated: true, completion: nil)
                    
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI

private extension P2PViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        bind(position: .right, barButtonItems: .kto(.record))
        
        tableView.estimatedRowHeight = 208.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
    }
    
    func binding() {
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
        
        tableView.rx
            .modelSelected(P2PGame.self)
            .bind { [unowned self] (data) in
                self.checkTurnOver(p2pGame: data)
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
