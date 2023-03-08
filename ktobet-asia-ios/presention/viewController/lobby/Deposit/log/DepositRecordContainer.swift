import RxSwift
import SharedBu
import SwiftUI
import UIKit

class DepositRecordContainer: LobbyViewController {
  @IBOutlet weak var containView: UIView!

  private lazy var depositRecordVC: DepositRecordDetailViewController = {
    let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
    var viewController = storyboard
      .instantiateViewController(withIdentifier: "DepositRecordDetailViewController") as! DepositRecordDetailViewController
    viewController.displayId = self.displayId
    return viewController
  }()

  private var presentingVC: UIViewController?

  var displayId: String!
  var paymentCurrencyType: PaymentLogDTO.PaymentCurrencyType?
  var transactionType: TransactionType?
  @Injected private var depositLogViewModel: DepositLogViewModel
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    // Deposit refactor feature兼容舊的流程
    if let paymentType = paymentCurrencyType {
      // new flow
      fetchData(paymentType)
    }
    else {
      // old flow
      switch transactionType {
      case .cryptodeposit?:
        updateTransactionType()
      case .deposit?:
        fetchData(.fiat)
      default:
        updateTransactionType()
      }
    }
  }

  deinit {
    if let vc = presentingVC {
      self.removeChildViewController(vc)
    }
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func updateTransactionType() {
    let _ = depositLogViewModel.getDepositLog(displayId).subscribe(onSuccess: { [weak self] in
      self?.fetchData($0.currencyType)
    }, onFailure: { [weak self] in
      self?.handleErrors($0)
    })
  }

  func fetchData(_ paymentType: PaymentLogDTO.PaymentCurrencyType) {
    switch paymentType {
    case .crypto:
      let vc = DepositCryptoRecordViewController(transactionId: displayId)
      self.addChildViewController(vc, inner: self.containView)
      self.presentingVC = vc
    case .fiat:
      self.addChildViewController(depositRecordVC, inner: containView)
      self.presentingVC = depositRecordVC
    default:
      break
    }
  }
}
