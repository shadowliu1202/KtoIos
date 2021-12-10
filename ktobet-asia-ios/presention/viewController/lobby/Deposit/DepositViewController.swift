import UIKit
import SwiftUI
import RxSwift
import SharedBu

class DepositViewController: UIViewController {
    @IBOutlet private weak var depositDescriptionLabel: UILabel!
    @IBOutlet private weak var depositNoDataLabel: UILabel!
    @IBOutlet private weak var depositTypeTableView: UITableView!
    @IBOutlet private weak var constraintDepositTypeTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintDepositRecordTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var depositRecordTitleLabel: UILabel!
    @IBOutlet private weak var depositRecordNoDataLabel: UILabel!
    @IBOutlet private weak var showAllRecordButton: UIButton!
    @IBOutlet private weak var depositRecordTableView: UITableView!
    
    private var viewModel = DI.resolve(DepositViewModel.self)!
    private var disposeBag = DisposeBag()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("common_deposit"))
        initUI()
        depositTypeDataBinding()
        recordDataBinding()
        depositTypeDataHandler()
        recordDataHandler()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    // MARK: BUTTON ACTION
    @IBAction func showAllRecord(sender: UIButton) {
        performSegue(withIdentifier: DepositRecordViewController.segueIdentifier, sender: nil)
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        depositDescriptionLabel.text = Localize.string("deposit_title_tips")
        depositRecordTitleLabel.text = Localize.string("deposit_log")
        showAllRecordButton.setTitle(Localize.string("common_show_all"), for: .normal)
        depositNoDataLabel.text = Localize.string("deposit_no_available_type")
        depositRecordNoDataLabel.text = Localize.string("deposit_no_records")
        depositRecordTableView.isHidden = true
        depositTypeTableView.isHidden = true
        depositTypeTableView.estimatedRowHeight = 56.0
        depositTypeTableView.rowHeight = UITableView.automaticDimension
        depositTypeTableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UITableView , obj == depositTypeTableView {
                constraintDepositTypeTableHeight.constant = (newvalue as! CGSize).height
            }
        }
    }
    
    fileprivate func depositTypeDataBinding() {
        let depositType = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.viewModel.getDepositType().asObservable()
        }).share(replay: 1)
        depositType.catchError({ [weak self] (error) -> Observable<[DepositType]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).do ( onNext:{[weak self] (depositTypes) in
            self?.depositTypeTableView.isHidden = false
            self?.depositTypeTableView.layoutIfNeeded()
            self?.depositTypeTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
            self?.depositTypeTableView.addTopBorder(size: 1, color: UIColor.dividerCapeCodGray2)
            if depositTypes.count == 0 {
                self?.depositNoDataLabel.isHidden = false
                self?.depositTypeTableView.isHidden = true
            } else {
                self?.depositNoDataLabel.isHidden = true
                self?.depositTypeTableView.isHidden = false
            }
        }).bind(to: depositTypeTableView.rx.items(cellIdentifier: String(describing: DepositTypeTableViewCell.self), cellType: DepositTypeTableViewCell.self)) { index, data, cell in
            cell.setUp(data: data, icon: self.viewModel.getDepositTypeImage(depositTypeId: data.paymentType.id))
        }.disposed(by: disposeBag)
    }
    
    fileprivate func depositTypeDataHandler() {
        Observable.zip(depositTypeTableView.rx.itemSelected, depositTypeTableView.rx.modelSelected(DepositType.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            if data.supportType == .Crypto {
                self.alertCryptoDepositWarnings()
            } else {
                self.performSegue(withIdentifier: DepositGatewayViewController.segueIdentifier, sender: data)
            }
            
            self.depositTypeTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func alertCryptoDepositWarnings() {
        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("deposit_crypto_warning"), confirm: {
            self.performSegue(withIdentifier: CryptoSelectorViewController.segueIdentifier, sender: nil)
        }, cancel: nil)
    }
    
    fileprivate func recordDataBinding() {
        let depositRecord = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.viewModel.getDepositRecord().asObservable()
        }).share(replay: 1)
        depositRecord.catchError({ [weak self] (error) -> Observable<[DepositRecord]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).do ( onNext:{[weak self] (depositRecord) in
            self?.depositRecordTableView.isHidden = false
            self?.constraintDepositRecordTableHeight.constant = CGFloat(depositRecord.count * 80)
            self?.depositRecordTableView.layoutIfNeeded()
            self?.depositRecordTableView.addBottomBorder(size: 1, color: UIColor.dividerCapeCodGray2)
            self?.depositRecordTableView.addTopBorder(size: 1, color: UIColor.dividerCapeCodGray2)
            if depositRecord.count == 0 {
                self?.depositRecordNoDataLabel.isHidden = false
                self?.depositRecordTableView.isHidden = true
                self?.showAllRecordButton.isHidden = true
            } else {
                self?.depositRecordNoDataLabel.isHidden = true
                self?.depositRecordTableView.isHidden = false
                self?.showAllRecordButton.isHidden = false
            }
        })
        .map({ $0.prefix(5) })
        .bind(to: depositRecordTableView.rx.items(cellIdentifier: String(describing: DepositRecordTableViewCell.self), cellType: DepositRecordTableViewCell.self)) { index, data, cell in
            cell.setUp(data: data)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func recordDataHandler() {
        Observable.zip(depositRecordTableView.rx.itemSelected, depositRecordTableView.rx.modelSelected(DepositRecord.self)).bind { [weak self] (indexPath, data) in
            let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "DepositRecordContainer") as! DepositRecordContainer
            vc.displayId = data.displayId
            self?.navigationController?.pushViewController(vc, animated: true)
            self?.depositRecordTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositGatewayViewController.segueIdentifier {
            if let dest = segue.destination as? DepositGatewayViewController {
                dest.depositType = sender as? DepositType
            }
        }
        
        if segue.identifier == DepositCryptoViewController.segueIdentifier {
            if let dest = segue.destination as? DepositCryptoViewController {
                dest.url = sender as? String
            }
        }
    }
    
    @IBAction func backToDeposit(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        if let vc = segue.source as? DepositOfflineConfirmViewController {
            if vc.depositSuccess {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
                toastView.show(on: self.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
            }
        }
        
        if let _ = segue.source as? DepositThirdPartWebViewController {
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
            toastView.show(on: self.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
        }
    }
    
}


extension DepositViewController {
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) { }
}
