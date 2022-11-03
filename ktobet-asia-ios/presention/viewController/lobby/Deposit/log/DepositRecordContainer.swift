import UIKit
import SwiftUI
import RxSwift
import SharedBu

class DepositRecordContainer: LobbyViewController {
    
    @IBOutlet weak var containView: UIView!
    
    private lazy var depositRecordVC: DepositRecordDetailViewController = {
        let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "DepositRecordDetailViewController") as! DepositRecordDetailViewController
        viewController.displayId = self.displayId
        return viewController
    }()
    private func cryptoDetailVC(data: PaymentLogDTO.CryptoLog) -> UIHostingController<DepositCryptoDetailView> {
        let viewController = DepositCryptoDetailView(data: data)
        let hostingController = UIHostingController(rootView: viewController)
        hostingController.navigationItem.hidesBackButton = true
        return hostingController
    }
    private var presentingVC: UIViewController?
    
    var displayId: String!
    var paymentCurrencyType: PaymentLogDTO.PaymentCurrencyType?
    var transactionType: TransactionType?
    private var depositLogViewModel = Injectable.resolve(DepositLogViewModel.self)!
    private var viewModel = Injectable.resolve(DepositViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        //Deposit refactor feature兼容舊的流程
        if let paymentType = paymentCurrencyType {
            // new flow
            fetchData(paymentType)
        } else {
            // old flow
            switch transactionType {
            case .cryptodeposit?:
                fetchData(.crypto)
            case .deposit?:
                fetchData(.fiat)
            default:
                updateTransactionType()
                break
            }
        }
    }
    
    deinit {
        if let vc = presentingVC {
            self.removeChildViewController(vc)
        }
        print("\(type(of: self)) deinit")
    }
    
    private func updateTransactionType() {
        let _ = depositLogViewModel.getDepositLog(displayId).subscribe(onSuccess: { [weak self] in
            self?.fetchData($0.currencyType)
        }, onError: { [weak self] in
            self?.handleErrors($0)
        })
    }
    
    func fetchData(_ paymentType: PaymentLogDTO.PaymentCurrencyType) {
        switch paymentType {
        case .crypto:
            depositLogViewModel.getDepositCryptoLog(transactionId: displayId)
                .take(1)
                .subscribe(onNext: { [weak self] in
                    guard let `self` = self else { return }
                    let vc = self.cryptoDetailVC(data: $0)
                    self.addChildViewController(vc, inner: self.containView)
                    self.presentingVC = vc
                }, onError: { [weak self] in
                    self?.handleErrors($0)
                }).disposed(by: self.disposeBag)
            break
        case .fiat:
            self.addChildViewController(depositRecordVC, inner: containView)
            self.presentingVC = depositRecordVC
            break
        default:
            break
        }
    }

}
