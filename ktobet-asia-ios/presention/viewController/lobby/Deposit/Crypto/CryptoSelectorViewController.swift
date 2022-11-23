import UIKit
import SharedBu
import RxSwift
import RxGesture

class CryptoSelectorViewController: LobbyViewController {
    
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var confrimButton: UIButton!
    @IBOutlet weak var videoTutorialBtn: UIButton!
    
    static let segueIdentifier = "toCryptoSelector"
    
    @Injected private var navigator: DepositNavigator

    @Injected private var localStorageRepo: LocalStorageRepository
    
    private var disposeBag = DisposeBag()
    
    @Injected var alert: AlertProtocol
        
    @Injected var viewModel: CryptoDepositViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        binding()
    }
    
    override func handleErrors(_ error: Error) {
        if error is PlayerDepositCountOverLimit {
            self.notifyTryLaterAndPopBack()
        } else {
            super.handleErrors(error)
        }
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
}

// MARK: - UI

private extension CryptoSelectorViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        guideLabel.isUserInteractionEnabled = true
        
        tableView.addBottomBorder()
        tableView.addTopBorder()
        
        videoTutorialBtn.isHidden = localStorageRepo.getSupportLocale() == .China()
    }
    
    func binding() {
        viewModel.output.webUrl
            .drive()
            .disposed(by: disposeBag)
        
        confrimButton.rx.tap
            .bind(to: viewModel.input.confirmTrigger)
            .disposed(by: disposeBag)
        
        guideLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [unowned self] _ in
                self.navigateToGuide()
            })
            .disposed(by: disposeBag)
        
        videoTutorialBtn.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.present(CryptoVideoTutorialViewController(), animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.options
            .drive(tableView.rx.items(
                cellIdentifier: "CryptoSelectorTableViewCell",
                cellType: CryptoSelectorTableViewCell.self)
            ) { index, item, cell in
                
                cell.img.image = UIImage(named: item.icon)
                cell.name.text = item.option.name
                cell.hint.text = item.option.promotion
                cell.selectRadioButton.isSelected = item.isSelected
            }
            .disposed(by: disposeBag)
        
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
        
        tableView.rx
            .observe(\.contentSize)
            .subscribe { size in
                if let height = size.element?.height {
                    self.tableViewHeightConstraint.constant = height
                }
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(CryptoDepositItemViewModel.self)
            .bind { [weak self] data in
                guard let self = self else { return }
                self.viewModel.input.selectPaymentGateway.onNext(data.option)
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    func notifyTryLaterAndPopBack() {
        alert.show(
            nil,
            Localize.string("deposit_notify_request_later"),
            confirm: {
                NavigationManagement.sharedInstance.popViewController()
            },
            cancel: nil
        )
    }
    
    func navigateToGuide() {
        navigator.toGuidePage(localStorageRepo.getSupportLocale())
    }
}

// MARK: - UITableViewDelegate

extension CryptoSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.5
    }
}
