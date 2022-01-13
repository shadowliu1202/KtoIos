import UIKit
import SwiftUI
import RxSwift
import SharedBu

class DepositRecordContainer: APPViewController {
    
    @IBOutlet weak var containView: UIView!
    
    private lazy var depositRecordVC: DepositRecordDetailViewController = {
        let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "DepositRecordDetailViewController") as! DepositRecordDetailViewController
        viewController.displayId = self.displayId
        return viewController
    }()
    private func cryptoDetailVC(data: DepositDetail.Crypto) -> UIHostingController<DepositCryptoDetailView> {
        let viewController = DepositCryptoDetailView(data: data)
        let hostingController = UIHostingController(rootView: viewController)
        hostingController.navigationItem.hidesBackButton = true
        return hostingController
    }
    private var presentingVC: UIViewController?
    
    var displayId: String!
    
    private var viewModel = DI.resolve(DepositViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        self.viewModel.getDepositRecordDetail(transactionId: displayId).subscribe(onSuccess: { [weak self] (detail) in
            self?.switchContain(detail)
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: self.disposeBag)
    }
    
    deinit {
        if let vc = presentingVC {
            self.removeChildViewController(vc)
        }
        print("\(type(of: self)) deinit")
    }
    
    private func switchContain(_ detail: DepositDetail) {
        switch detail {
        case is DepositDetail.General:
            self.addChildViewController(depositRecordVC, inner: containView)
            self.presentingVC = depositRecordVC
        case let data as DepositDetail.Crypto:
            let vc = cryptoDetailVC(data: data)
            self.addChildViewController(vc, inner: containView)
            self.presentingVC = vc
        case is DepositDetail.Flat:
            self.addChildViewController(depositRecordVC, inner: containView)
            self.presentingVC = depositRecordVC
        default:
            break
        }
    }

}
