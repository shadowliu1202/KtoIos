import RxSwift
import sharedbu
import UIKit

class WithdrawalFiatWalletsViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected private var alert: AlertProtocol
    @Injected private var viewModel: WithdrawalFiatWalletsViewModel

    private let disposeBag = DisposeBag()

    init(
        viewModel: WithdrawalFiatWalletsViewModel? = nil,
        alert: AlertProtocol? = nil)
    {
        if let viewModel {
            self._viewModel.wrappedValue = viewModel
        }

        if let alert {
            self._alert.wrappedValue = alert
        }

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

extension WithdrawalFiatWalletsViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            action: #selector(tapBack))

        addSubView(
            from: { [unowned self] in
                WithdrawalFiatWalletsView(
                    viewModel: self.viewModel,
                    toAddWallet: {
                        self.navigationController?.pushViewController(
                            WithdrawalAddFiatBankCardViewController(),
                            animated: true)
                    },
                    toBack: {
                        NavigationManagement.sharedInstance.popViewController()
                    },
                    onUpToMaximum: {
                        self.popMaximumAlert()
                    },
                    onWalletSelected: {
                        self.handleWalletSelect($0, isEditing: $1)
                    })
            },
            to: view)
    }

    private func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    @objc
    private func tapBack() {
        if viewModel.isEditing {
            viewModel.isEditing = !viewModel.isEditing
        }
        else {
            NavigationManagement.sharedInstance.popViewController()
        }
    }

    func handleWalletSelect(_ wallet: WithdrawalDto.FiatWallet, isEditing: Bool) {
        if isEditing {
            self.navigationController?
                .pushViewController(
                    WithdrawalFiatWalletDetailViewController(wallet: wallet),
                    animated: true)
        }
        else {
            self.navigationController?
                .pushViewController(
                    WithdrawalFiatRequestStep1ViewController(wallet: wallet),
                    animated: true)
        }
    }

    func popMaximumAlert() {
        alert.show(
            Localize.string("common_kindly_remind"),
            Localize.string("withdrawal_bankcard_add_overlimit", "\(viewModel.playerWallet?.maxAmount ?? 3)"),
            confirm: nil,
            cancel: nil)
    }
}
