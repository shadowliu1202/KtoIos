import UIKit
import RxSwift
import share_bu

class DepositViewController: UIViewController {
    @IBOutlet private weak var depositTitleLabel: UILabel!
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
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        initUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        depositTypeDataBinding()
        recordDataBinding()
        depositTypeDataHandler()
        recordDataHandler()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disposeBag = DisposeBag()
        NavigationManagement.sharedInstance.removeViewControllers(vcId: "DepositNavigation")
    }
    
    // MARK: BUTTON ACTION
    @IBAction func showAllRecord(sender: UIButton) {
        performSegue(withIdentifier: DepositRecordViewController.segueIdentifier, sender: nil)
    }

    // MARK: METHOD
    fileprivate func initUI() {
        depositTitleLabel.text = Localize.string("common_deposit")
        depositDescriptionLabel.text = Localize.string("deposit_title_tips")
        depositRecordTitleLabel.text = Localize.string("deposit_log")
        showAllRecordButton.setTitle(Localize.string("common_show_all"), for: .normal)
        depositNoDataLabel.text = Localize.string("deposit_no_available_type")
        depositRecordNoDataLabel.text = Localize.string("deposit_no_records")
        depositRecordTableView.isHidden = true
        depositTypeTableView.isHidden = true
    }
    
    fileprivate func depositTypeDataBinding() {
        depositTypeTableView.delegate = nil
        depositTypeTableView.dataSource = nil
        let getDepositTypeObservable = viewModel.getDepositType().catchError { _ in Single<[DepositRequest.DepositType]>.never() }.asObservable().map { (data) -> [DepositRequest.DepositType] in
            return data.filter { (d) -> Bool in
                return (d as? DepositRequest.DepositTypeUnknown) == nil
            }
        }.share(replay: 1)
        
        getDepositTypeObservable.bind(to: depositTypeTableView.rx.items(cellIdentifier: String(describing: DepositTypeTableViewCell.self), cellType: DepositTypeTableViewCell.self)) { index, data, cell in
            if let thirdParty = data as? DepositRequest.DepositTypeThirdParty {
                cell.setUp(name: thirdParty.name, icon: self.viewModel.getDepositTypeImage(depositTypeId: thirdParty.depositTypeId)!, isRecommend: thirdParty.isFavorite)
                return
            }

            if let offline = data as? DepositRequest.DepositTypeOffline {
                cell.setUp(name: Localize.string("deposit_offline_step1_title"), icon: self.viewModel.getDepositTypeImage(depositTypeId: offline.depositTypeId)!, isRecommend: offline.isFavorite)
                return
            }
        }.disposed(by: disposeBag)

        getDepositTypeObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe { [weak self] (depositTypes) in
                self?.depositTypeTableView.isHidden = false
                self?.constraintDepositTypeTableHeight.constant = CGFloat(depositTypes.count * 56)
                self?.depositTypeTableView.layoutIfNeeded()
                self?.depositTypeTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
                self?.depositTypeTableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
                if depositTypes.count == 0 {
                    self?.depositNoDataLabel.isHidden = false
                    self?.depositTypeTableView.isHidden = true
                } else {
                    self?.depositNoDataLabel.isHidden = true
                    self?.depositTypeTableView.isHidden = false
                }
            } onError: { (error) in
                self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func depositTypeDataHandler() {
        Observable.zip(depositTypeTableView.rx.itemSelected, depositTypeTableView.rx.modelSelected(DepositRequest.DepositType.self)).bind { [weak self] (indexPath, data) in
            self?.performSegue(withIdentifier: DepositMethodViewController.segueIdentifier, sender: data)
            self?.depositTypeTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }

    fileprivate func recordDataBinding() {
        depositRecordTableView.delegate = nil
        depositRecordTableView.dataSource = nil
        let getDepositRecordObservable = viewModel.getDepositRecord().catchError { _ in Single<[DepositRecord]>.never() }.asObservable().share(replay: 1)
        getDepositRecordObservable.bind(to: depositRecordTableView.rx.items(cellIdentifier: String(describing: DepositRecordTableViewCell.self), cellType: DepositRecordTableViewCell.self)) { index, data, cell in
            cell.setUp(data: data)
        }.disposed(by: disposeBag)
        
        getDepositRecordObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe { [weak self] (depositRecord) in
                self?.depositRecordTableView.isHidden = false
                self?.constraintDepositRecordTableHeight.constant = CGFloat(depositRecord.count * 80)
                self?.depositRecordTableView.layoutIfNeeded()
                self?.depositRecordTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
                self?.depositRecordTableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
                if depositRecord.count == 0 {
                    self?.depositRecordNoDataLabel.isHidden = false
                    self?.depositRecordTableView.isHidden = true
                    self?.showAllRecordButton.isHidden = true
                } else {
                    self?.depositRecordNoDataLabel.isHidden = true
                    self?.depositRecordTableView.isHidden = false
                    self?.showAllRecordButton.isHidden = false
                }
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)
    }
    
    fileprivate func recordDataHandler() {
        Observable.zip(depositRecordTableView.rx.itemSelected, depositRecordTableView.rx.modelSelected(DepositRecord.self)).bind {(indexPath, data) in
            self.performSegue(withIdentifier: DepositRecordDetailViewController.segueIdentifier, sender: data)
            self.depositRecordTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositMethodViewController.segueIdentifier {
            if let dest = segue.destination as? DepositMethodViewController {
                dest.depositType = sender as? DepositRequest.DepositType
            }
        }
        
        if segue.identifier == DepositRecordDetailViewController.segueIdentifier {
            if let dest = segue.destination as? DepositRecordDetailViewController {
                dest.detailRecord = sender as? DepositRecord
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
