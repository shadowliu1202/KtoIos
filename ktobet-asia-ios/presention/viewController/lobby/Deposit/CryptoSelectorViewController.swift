import UIKit
import SharedBu
import RxSwift

class CryptoSelectorViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confrimButton: UIButton!
    
    static let segueIdentifier = "toCryptoSelector"
    
    private var viewModel = DI.resolve(DepositViewModel.self)!
    private var disposeBag = DisposeBag()
    private var selectedIndex = 0
    private var selectedType: SupportCryptoType? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        tableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
        tableView.addTopBorder(size: 1, color: UIColor.dividerCapeCodGray2)
        
        tableView.rx.observe(CGSize.self, #keyPath(UITableView.contentSize)).asObservable()
            .subscribe { size in
                if let height = size.element??.height {
                    self.tableViewHeightConstraint.constant = height
                }
            }.disposed(by: disposeBag)
        
        viewModel.getDepositTakingCryptos().asObservable().bind(to: tableView.rx.items(cellIdentifier: String(describing: CryptoSelectorTableViewCell.self), cellType: CryptoSelectorTableViewCell.self)) {[weak self] (index, item, cell) in
            guard let self = self else { return }
            cell.img.image = self.getIcon(supportCryptoType: item.type)
            cell.name.text = item.type?.name
            cell.hint.text = item.promotion
            if index == self.selectedIndex {
                cell.selectRadioButton.isSelected = true
                self.selectedType = item.type
            }
        }.disposed(by: disposeBag)
        
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(TakingCrypto.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            guard let cell = self.tableView.cellForRow(at: indexPath) as? CryptoSelectorTableViewCell else { return }
            guard let lastCell = self.tableView.cellForRow(at: IndexPath(item: self.selectedIndex, section: 0)) as? CryptoSelectorTableViewCell else { return }
            lastCell.unSelectRow()
            cell.selectRow()
            self.selectedIndex = indexPath.row
            self.selectedType = data.type
        }.disposed(by: disposeBag)
        
        confrimButton.rx.touchUpInside.subscribe(onNext: {[weak self] in
            guard let self = self, let currencyId = self.selectedType?.currencyId else { return }
            print(currencyId)
            self.viewModel.createCryptoDeposit(cryptoDepositRequest: CryptoDepositRequest(cryptoCurrency: currencyId))
                .subscribe { url in
                self.performSegue(withIdentifier: DepositCryptoViewController.segueIdentifier, sender: url)
            } onError: {[weak self] error in
                self?.handleUnknownError(error)
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositCryptoViewController.segueIdentifier {
            if let dest = segue.destination as? DepositCryptoViewController {
                dest.url = sender as? String
            }
        }
    }
    
    private func getIcon(supportCryptoType: SupportCryptoType?) -> UIImage? {
        guard let type = supportCryptoType else { return nil }
        switch type {
        case .eth:
            return UIImage(named: "Main_ETH")
        case .usdt:
            return UIImage(named: "Main_USDT")
        case .usdc:
            return UIImage(named: "Main_USDC")
        default:
            return nil
        }
    }
}
