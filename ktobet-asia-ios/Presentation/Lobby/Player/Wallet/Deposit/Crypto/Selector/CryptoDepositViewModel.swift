import Foundation
import RxCocoa
import RxSwift
import sharedbu

protocol CryptoDepositViewModelProtocol {
  var options: [CryptoDepositItemViewModel] { get }
  var selected: CryptoDepositItemViewModel? { get }
  var submitButtonDisable: Bool { get }
  func fetchOptions()
  func setSelected(item: CryptoDepositItemViewModel?)
  func confirm() -> Single<CommonDTO.WebUrl>
}

class CryptoDepositViewModel:
  CollectErrorViewModel,
  CryptoDepositViewModelProtocol,
  ObservableObject
{
  private let depositService: IDepositAppService
  private let disposeBag = DisposeBag()

  @Published private(set) var options: [CryptoDepositItemViewModel] = []
  @Published private(set) var selected: CryptoDepositItemViewModel?
  @Published private(set) var submitButtonDisable = false

  init(depositService: IDepositAppService) {
    self.depositService = depositService
  }

  func fetchOptions() {
    getPayments()
      .compactMap { $0.crypto }
      .flatMap { RxSwift.Single.from($0.options) }
      .map { $0 as! [PaymentsDTO.TypeOptions] }
      .map {
        $0.map {
          CryptoDepositItemViewModel(with: $0, icon: self.getIconNamed($0.cryptoType), isSelected: false)
        }
      }
      .subscribe(onNext: { [weak self] in
        self?.options = $0
        self?.setSelected(item: $0.first)
      })
      .disposed(by: disposeBag)
  }

  func setSelected(item: CryptoDepositItemViewModel?) {
    options.forEach {
      $0.isSelected = $0.option == item?.option ? true : false
    }
    selected = item
  }

  func confirm() -> Single<CommonDTO.WebUrl> {
    guard let option = selected?.option else {
      return .error(KTOError.EmptyData)
    }
    return Single
      .from(
        self.depositService
          .requestCryptoDeposit(
            request: CryptoDepositDTO.Request(typeOptionsId: option.optionsId)))
      .compose(applySingleErrorHandler())
      .do(
        onSubscribe: { [weak self] in
          self?.submitButtonDisable = true
        },
        onDispose: { [weak self] in
          self?.submitButtonDisable = false
        })
  }

  private func getPayments() -> Observable<PaymentsDTO> {
    Observable
      .from(depositService.getPayments())
      .compose(applyObservableErrorHandle())
  }

  private func getIconNamed(_ type: PaymentsDTO.TypeOptionsType) -> String {
    switch type {
    case .eth:
      return "Main_ETH"
    case .usdt:
      return "Main_USDT"
    case .usdc:
      return "Main_USDC"
    default:
      return ""
    }
  }
}
