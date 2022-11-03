import UIKit
import SharedBu
import RxSwift

class CryptoSelectorViewController: LobbyViewController {
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confrimButton: UIButton!
    var alert: AlertProtocol = Injectable.resolve(AlertProtocol.self)!
    
    static let segueIdentifier = "toCryptoSelector"
    
    var viewModel = Injectable.resolve(CryptoDepositViewModel.self)!
    private let navigator = Injectable.resolve(DepositNavigator.self)!
    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        bindViewModel()
    }
    
    private func initUI() {
        self.guideLabel.isUserInteractionEnabled = true
        tableView.addBottomBorder()
        tableView.addTopBorder()
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        confrimButton.rx.tap.bind(to: viewModel.input.confirmTrigger).disposed(by: disposeBag)
        viewModel.output.webUrl.drive().disposed(by: disposeBag)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToGuide))
        guideLabel.addGestureRecognizer(tapGesture)
        
        tableView.rx.observe(CGSize.self, #keyPath(UITableView.contentSize)).asObservable()
            .subscribe { size in
                if let height = size.element??.height {
                    self.tableViewHeightConstraint.constant = height
                }
            }.disposed(by: disposeBag)
        
        viewModel.output.options.drive(tableView.rx.items(cellIdentifier: String(describing: CryptoSelectorTableViewCell.self), cellType: CryptoSelectorTableViewCell.self)) { index, item, cell in
            cell.img.image = UIImage(named: item.icon)
            cell.name.text = item.option.name
            cell.hint.text = item.option.promotion
            cell.selectRadioButton.isSelected = item.isSelected
        }.disposed(by: disposeBag)
        
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(CryptoDepositItemViewModel.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            self.viewModel.input.selectPaymentGateway.onNext(data.option)
        }.disposed(by: disposeBag)
        
        viewModel.errors().subscribe(onNext: {[weak self] error in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        if error is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func notifyTryLaterAndPopBack() {
        alert.show(nil, Localize.string("deposit_notify_request_later"), confirm: {
            NavigationManagement.sharedInstance.popViewController()
        }, cancel: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositCryptoViewController.segueIdentifier {
            if let dest = segue.destination as? DepositCryptoViewController {
                dest.url = sender as? String
            }
        }
    }
    
    @IBAction func clickGuideBtn(_ sender: Any) {
        navigateToGuide()
    }
    
    @objc private func navigateToGuide() {
        navigator.toGuidePage(localStorageRepo.getSupportLocale())
    }
}

extension CryptoSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.5
    }
}
