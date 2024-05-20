import Foundation
import RxSwift
import sharedbu

protocol WithdrawalFiatWalletDetailViewModelProtocol {
    var supportLocale: SupportLocale { get }
    var realName: String { get }
    var wallet: WithdrawalDto.FiatWallet? { get }
    var isDeleteSuccess: Bool { get }
    var isDeleteButtonDisable: Bool { get }

    func prepareForAppear(wallet: WithdrawalDto.FiatWallet)

    func loadRealName()
    func deleteWallet()
}

class WithdrawalFiatWalletDetailViewModel:
    CollectErrorViewModel,
    WithdrawalFiatWalletDetailViewModelProtocol,
    ObservableObject
{
    @Published private(set) var wallet: WithdrawalDto.FiatWallet?
    @Published private(set) var isDeleteSuccess = false
    @Published private(set) var isDeleteButtonDisable = false
    @Published private(set) var realName = ""

    private let withdrawalService: IWithdrawalAppService
    private let playerDataUseCase: PlayerDataUseCase
    private let disposeBag = DisposeBag()

    let supportLocale: SupportLocale

    init(
        withdrawalService: IWithdrawalAppService,
        playerDataUseCase: PlayerDataUseCase,
        playerConfigure: PlayerConfiguration)
    {
        self.withdrawalService = withdrawalService
        self.playerDataUseCase = playerDataUseCase
        self.supportLocale = playerConfigure.supportLocale
    }

    func prepareForAppear(wallet: WithdrawalDto.FiatWallet) {
        self.wallet = wallet
    }
}

// MARK: - API

extension WithdrawalFiatWalletDetailViewModel {
    func loadRealName() {
        playerDataUseCase
            .loadPlayer()
            .map { $0.playerInfo.withdrawalName }
            .publish(to: self, \.realName)
            .collectError(to: self)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func deleteWallet() {
        Completable.from(
            withdrawalService.deleteWallet(walletId: wallet?.walletId ?? ""))
            .do(
                onSubscribe: { [weak self] in
                    self?.isDeleteButtonDisable = true
                },
                onDispose: { [weak self] in
                    self?.isDeleteButtonDisable = false
                })
            .subscribe(
                onCompleted: { [weak self] in
                    self?.isDeleteSuccess = true
                },
                onError: { [weak self] in
                    self?.errorsSubject.onNext($0)
                })
            .disposed(by: disposeBag)
    }
}
