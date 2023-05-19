import Foundation
import RxSwift
import SharedBu

protocol WithdrawalCryptoWalletDetailViewModelProtocol {
  var supportLocale: SupportLocale { get }
  var wallet: WithdrawalDto.CryptoWallet? { get }
  var isDeleteSuccess: Bool { get }
  var isDeleteButtonDisable: Bool { get }

  func prepareForAppear(wallet: WithdrawalDto.CryptoWallet)

  func deleteWallet()
}

class WithdrawalCryptoWalletDetailViewModel:
  CollectErrorViewModel,
  WithdrawalCryptoWalletDetailViewModelProtocol,
  ObservableObject
{
  @Published private(set) var wallet: WithdrawalDto.CryptoWallet?
  @Published private(set) var isDeleteSuccess = false
  @Published private(set) var isDeleteButtonDisable = false

  private let withdrawalService: IWithdrawalAppService
  private let disposeBag = DisposeBag()

  let supportLocale: SupportLocale

  init(
    withdrawalService: IWithdrawalAppService,
    playerConfigure: PlayerConfiguration)
  {
    self.withdrawalService = withdrawalService
    self.supportLocale = playerConfigure.supportLocale
  }

  func prepareForAppear(wallet: WithdrawalDto.CryptoWallet) {
    self.wallet = wallet
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - API

extension WithdrawalCryptoWalletDetailViewModel {
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
