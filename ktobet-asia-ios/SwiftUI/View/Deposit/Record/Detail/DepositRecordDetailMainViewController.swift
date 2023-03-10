import RxSwift
import SharedBu
import SwiftUI
import UIKit

class DepositRecordDetailMainViewController: LobbyViewController {
  @Injected private var depositLogViewModel: DepositRecordDetailViewModel

  private let disposeBag = DisposeBag()

  private let displayId: String

  private var paymentCurrencyType: PaymentLogDTO.PaymentCurrencyType?
  private var transactionType: TransactionType?

  private(set) var target: UIViewController?

  init(
    displayId: String,
    paymentCurrencyType: PaymentLogDTO.PaymentCurrencyType? = nil,
    transactionType: TransactionType? = nil)
  {
    self.displayId = displayId
    self.paymentCurrencyType = paymentCurrencyType
    self.transactionType = transactionType

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black131313

    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    // Deposit refactor feature兼容舊的流程
    if let paymentType = paymentCurrencyType {
      // new flow
      addContainer(paymentType)
    }
    else {
      // old flow
      switch transactionType {
      case .cryptodeposit?:
        updateTransactionType()
      case .deposit?:
        addContainer(.fiat)
      default:
        updateTransactionType()
      }
    }
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func updateTransactionType() {
    depositLogViewModel
      .getDepositLog(displayId)
      .subscribe(onSuccess: { [weak self] in
        self?.addContainer($0.currencyType)
      }, onFailure: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)
  }

  private func addContainer(_ paymentType: PaymentLogDTO.PaymentCurrencyType) {
    let target: UIViewController

    switch paymentType {
    case .crypto:
      target = DepositCryptoRecordDetailViewController(transactionId: displayId)

    case .fiat:
      target = DepositRecordDetailViewController(transactionId: displayId)

    default:
      return
    }

    self.target = target

    addChild(target)

    view.addSubview(target.view)
    target.view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    target.didMove(toParent: self)
  }
}
