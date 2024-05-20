import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalRecordDetailMainViewController: LobbyViewController {
    @Injected private var viewModel: WithdrawalRecordDetailViewModel

    private let disposeBag = DisposeBag()

    private let displayId: String

    private var paymentCurrencyType: WithdrawalDto.LogCurrencyType?

    private(set) var target: UIViewController?

    init(
        displayId: String,
        paymentCurrencyType: WithdrawalDto.LogCurrencyType? = nil)
    {
        self.displayId = displayId
        self.paymentCurrencyType = paymentCurrencyType

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .greyScaleDefault

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        // FIXME: Withdrawal refactor feature兼容舊的流程
        if let paymentType = paymentCurrencyType {
            // new flow
            addContainer(paymentType)
        }
        else {
            // old flow
            updateTransactionType()
        }
    }

    private func updateTransactionType() {
        viewModel
            .getWithdrawalLog(displayId)
            .subscribe(onSuccess: { [weak self] in
                self?.addContainer($0.type)
            }, onFailure: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }

    private func addContainer(_ paymentType: WithdrawalDto.LogCurrencyType) {
        let target: UIViewController

        switch paymentType {
        case .crypto:
            target = WithdrawalCryptoRecordDetailViewController(displayId: displayId)

        case .fiat:
            target = WithdrawalRecordDetailViewController(transactionId: displayId)
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
