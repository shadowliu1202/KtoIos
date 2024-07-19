import RxSwift
import sharedbu

protocol WithdrawalCryptoWalletsViewModelProtocol: AnyObject {
    var supportLocale: SupportLocale { get }
    var playerWallet: WithdrawalDto.PlayerCryptoWallet? { get }
    var isUpToMaximum: Bool { get }
    var isEditing: Bool { get set }

    func observeWallets()
    func resetDisposeBag()
}

class WithdrawalCryptoWalletsViewModel:
    CollectErrorViewModel,
    WithdrawalCryptoWalletsViewModelProtocol,
    ObservableObject
{
    @Published private(set) var playerWallet: WithdrawalDto.PlayerCryptoWallet?

    @Published var isEditing = false

    private let withdrawalService: IWithdrawalAppService
    private var disposeBag = DisposeBag()
    private let supportCrypto: [SupportCryptoType]

    let supportLocale: SupportLocale

    var isUpToMaximum: Bool {
        playerWallet?.wallets.count ?? 0 >= playerWallet?.maxAmount ?? 5
    }

    init(
        withdrawalService: IWithdrawalAppService,
        playerConfig: PlayerConfiguration
    ) {
        self.withdrawalService = withdrawalService
        supportLocale = playerConfig.supportLocale
        supportCrypto = withdrawalService.getWalletSupportCryptoTypes()
    }

    func isValidWallet(wallet: WithdrawalDto.CryptoWallet) -> Bool {
        supportCrypto.contains(wallet.type) && wallet.type.supportNetwork().contains(wallet.network)
    }

    func observeWallets() {
        Observable.from(
            withdrawalService.getCryptoWallets())
            .publish(to: self, \.playerWallet)
            .collectError(to: self)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func resetDisposeBag() {
        disposeBag = DisposeBag()
    }
}

// MARK: - Wallet Row Model
extension WithdrawalDto.CryptoWallet: WalletRowModel {
    var title: String {
        "\(name)\n\(type.name) \(network.name)"
    }
    
    
    var accountNumber: String {
        address
    }
}
