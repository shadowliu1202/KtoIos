import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalOTPVerifyMethodSelectViewController:
    LobbyViewController &
    SwiftUIConverter
{
    @Injected private var viewModel: WithdrawalOTPVerifyMethodSelectViewModel
    @Injected private var alert: AlertProtocol

    private let bankCardID: String

    private let disposeBag = DisposeBag()

    init(
        viewModel: WithdrawalOTPVerifyMethodSelectViewModel? = nil,
        alert: AlertProtocol? = nil,
        bankCardID: String)
    {
        if let viewModel {
            self._viewModel.wrappedValue = viewModel
        }

        if let alert {
            self._alert.wrappedValue = alert
        }

        self.bankCardID = bankCardID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        binding()
    }
}

// MARK: - UI

extension WithdrawalOTPVerifyMethodSelectViewController {
    func setupUI() {
        NavigationManagement.sharedInstance
            .addBarButtonItem(
                vc: self,
                barItemType: .close)

        addSubView(
            from: {
                WithdrawalOTPVerifyMethodSelectView(
                    viewModel: viewModel,
                    bankCardID: bankCardID,
                    otpServiceUnavailable: { [weak self] in
                        self?.alertAllMethodsUnavailableThenPopBack()
                    },
                    otpRequestOnCompleted: { [weak self] selectedAccountType in
                        self?.pushToOTPVerificationPage(selectedAccountType)
                    })
                    .environment(\.playerLocale, viewModel.getSupportLocale())
            }, to: view)
    }

    func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Navigation

extension WithdrawalOTPVerifyMethodSelectViewController {
    func pushToOTPVerificationPage(_ selectedAccountType: sharedbu.AccountType) {
        navigationController?
            .pushViewController(
                WithdrawalOTPVerificationViewController(accountType: selectedAccountType),
                animated: true)
    }

    func alertAllMethodsUnavailableThenPopBack() {
        alert
            .show(
                Localize.string("common_error"),
                Localize.string("cps_otp_service_down"),
                confirm: { [weak self] in
                    self?.navigationController?.popToRootViewController(animated: true)
                },
                cancel: nil)
    }
}
