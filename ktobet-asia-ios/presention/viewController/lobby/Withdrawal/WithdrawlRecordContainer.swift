import RxSwift
import SharedBu
import SwiftUI
import UIKit

class WithdrawlRecordContainer: LobbyViewController {
  @IBOutlet weak var containView: UIView!

  private lazy var withdrawalRecordVC: WithdrawalRecordDetailViewController = {
    let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
    var viewController = storyboard
      .instantiateViewController(
        withIdentifier: "WithdrawalRecordDetailViewController") as! WithdrawalRecordDetailViewController
    viewController.displayId = displayId
    viewController.transactionTransactionType = transactionTransactionType
    return viewController
  }()

  private func withdrawalDetailVC(data: WithdrawalDetail.Crypto) -> UIHostingController<WithdrawalCryptoDetailView> {
    let viewController = WithdrawalCryptoDetailView(data: data)
    let hostingController = UIHostingController(rootView: viewController)
    hostingController.navigationItem.hidesBackButton = true
    hostingController.view.backgroundColor = .black131313
    return hostingController
  }

  private var presentingVC: UIViewController?

  var transactionTransactionType: TransactionType!
  var displayId: String!

  private var viewModel = Injectable.resolve(WithdrawalViewModel.self)!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    self.viewModel.getWithdrawalRecordDetail(transactionId: displayId, transactionTransactionType: transactionTransactionType)
      .subscribe(
        onNext: { [weak self] withdrawalDetail in
          self?.switchContain(withdrawalDetail)
        },
        onError: { [weak self] error in
          self?.handleErrors(error)
        }).disposed(by: self.disposeBag)
  }

  deinit {
    if let vc = presentingVC {
      self.removeChildViewController(vc)
    }
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func switchContain(_ detail: WithdrawalDetail) {
    switch detail {
    case is WithdrawalDetail.General:
      self.addChildViewController(withdrawalRecordVC, inner: containView)
      self.presentingVC = withdrawalRecordVC
    case let data as WithdrawalDetail.Crypto:
      let vc = withdrawalDetailVC(data: data)
      self.addChildViewController(vc, inner: containView)
      self.presentingVC = vc
    default:
      break
    }
  }
}
