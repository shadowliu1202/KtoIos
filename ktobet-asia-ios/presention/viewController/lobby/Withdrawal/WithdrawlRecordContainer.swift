import UIKit
import SwiftUI
import RxSwift
import SharedBu

class WithdrawlRecordContainer: UIViewController {

    @IBOutlet weak var containView: UIView!
    
    private lazy var withdrawalRecordVC: WithdrawalRecordDetailViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawalRecordDetailViewController") as! WithdrawalRecordDetailViewController
        viewController.displayId = displayId
        viewController.transactionTransactionType = transactionTransactionType
        return viewController
    }()
    private func withdrawalDetailVC(data: WithdrawalDetail.Crypto) -> UIHostingController<WithdrawalCryptoDetailView>{
        let viewController = WithdrawalCryptoDetailView(data: data)
        let hostingController = UIHostingController(rootView: viewController)
        hostingController.navigationItem.hidesBackButton = true
        return hostingController
    }
    private var presentingVC: UIViewController?
    
    var transactionTransactionType: TransactionType!
    var displayId: String!
    
    private var viewModel = DI.resolve(WithdrawalViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        self.viewModel.getWithdrawalRecordDetail(transactionId: displayId, transactionTransactionType: transactionTransactionType).subscribe(onSuccess: { [weak self] (withdrawalDetail) in
            self?.switchContain(withdrawalDetail)
        }, onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: self.disposeBag)
    }
    
    deinit {
        if let vc = presentingVC {
            self.removeChildViewController(vc)
        }
        print("\(type(of: self)) deinit")
    }
    
    private func switchContain(_ detail: WithdrawalDetail) {
        switch detail {
        case is WithdrawalDetail.General:
            self.addChildViewController(withdrawalRecordVC, inner: containView)
            self.presentingVC = withdrawalRecordVC
            break
        case let data as WithdrawalDetail.Crypto:
            let vc = withdrawalDetailVC(data: data)
            self.addChildViewController(vc, inner: containView)
            self.presentingVC = vc
            break
        default:
            break
        }
    }

}
