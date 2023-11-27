import Foundation
import RxCocoa
import RxSwift
import sharedbu

protocol DepositViewModelProtocol {
  var selections: [DepositSelection]? { get }
  var recentLogs: [PaymentLogDTO.Log]? { get }

  func setup()
  func resetSubscription()
}

class DepositViewModel: CollectErrorViewModel,
  DepositViewModelProtocol,
  ObservableObject
{
  private let depositService: IDepositAppService

  private var disposeBag = DisposeBag()

  @Published private(set) var selections: [DepositSelection]?
  @Published private(set) var recentLogs: [PaymentLogDTO.Log]?

  init(depositService: IDepositAppService) {
    self.depositService = depositService
  }
}

// MARK: - API

extension DepositViewModel {
  func setup() {
    fetchPayments()
    fetchRecentPaymentLogs()
  }

  private func fetchPayments() {
    Observable.from(depositService.getPayments())
      .compose(applyObservableErrorHandle())
      .map { [unowned self] in
        self.buildSelections($0)
      }
      .catchAndReturn([])
      .subscribe(onNext: { [unowned self] in
        self.selections = $0
      })
      .disposed(by: disposeBag)
  }

  private func fetchRecentPaymentLogs() {
    Observable.from(
      depositService.getRecentPaymentLogs())
      .map { $0.compactMap { $0 as? PaymentLogDTO.Log } }
      .compose(applyObservableErrorHandle())
      .catchAndReturn([])
      .subscribe(onNext: { [unowned self] in
        self.recentLogs = $0
      })
      .disposed(by: disposeBag)
  }
  
  func resetSubscription() {
    disposeBag = .init()
  }
}

// MARK: - Data Handle

extension DepositViewModel {
  func buildSelections(_ payments: PaymentsDTO) -> [DepositSelection] {
    var list: [DepositSelection] = []

    if let offline = payments.offline {
      list.append(OfflinePayment(offline))
    }

    let online = payments.fiat.compactMap { OnlinePayment($0) }
    list.append(contentsOf: online)

    if let crypto = payments.crypto {
      list.append(CryptoPayment(crypto))
    }

    if let cryptoMarket = payments.cryptoMarket {
      list.append(CryptoMarket(cryptoMarket))
    }

    return list
  }
}
