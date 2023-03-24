import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt
import SharedBu

protocol DepositOfflineConfirmViewModelProtocol {
  var receiverInfo: DepositOfflineConfirmModel.ReceiverInfo { get }
  var remitTip: DepositOfflineConfirmModel.RemitTip { get }
  var validTimeString: String { get }
  var locale: SupportLocale { get }

  var expiredDriver: Driver<Void> { get }
  var depositSuccessDriver: Driver<Void> { get }

  var depositTrigger: PublishSubject<Void> { get }

  var isAllowConfirm: Bool { get }

  func prepareForAppear(memo: OfflineDepositDTO.Memo, selectedBank: PaymentsDTO.BankCard)
  func startCounting()
}

class DepositOfflineConfirmViewModel:
  CollectErrorViewModel,
  DepositOfflineConfirmViewModelProtocol,
  ObservableObject
{
  @Published var receiverInfo: DepositOfflineConfirmModel.ReceiverInfo = .init()
  @Published var remitTip: DepositOfflineConfirmModel.RemitTip = .init()
  @Published var validTimeString = ""

  private let depositService: IDepositAppService
  private let expiredSubject = PublishSubject<Void>()
  private let depositSuccessSubject = PublishSubject<Void>()
  private let depositTracker = ActivityIndicator()
  private let disposeBag = DisposeBag()

  let locale: SupportLocale

  let depositTrigger: PublishSubject<Void> = .init()

  var expiredDriver: Driver<Void> { expiredSubject.asDriver(onErrorJustReturn: ()) }
  var depositSuccessDriver: Driver<Void> { depositSuccessSubject.asDriver(onErrorJustReturn: ()) }

  var isAllowConfirm: Bool { !depositTracker.isLoading }

  init(
    depositService: IDepositAppService,
    locale: SupportLocale)
  {
    self.depositService = depositService
    self.locale = locale

    super.init()

    depositTrigger
      .flatMapLatest { [unowned self] in
        self.deposit()
          .trackOnDispose(depositTracker)
          .asObservable()
          .materialize()
          .elements()
      }
      .subscribe(onNext: { [unowned self] _ in
        self.depositSuccessSubject.onNext(())
      })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - API

extension DepositOfflineConfirmViewModel {
  private func deposit() -> Single<Bool> {
    Completable.from(
      CompletableWrapperKt.wrap(
        depositService.confirmOfflineDeposit(
          beneficiaryIdentity: receiverInfo.identity)))
      .do(onError: { [unowned self] in self.errorsSubject.onNext($0) })
      .andThen(.just(true))
  }
}

// MARK: - Data Handle

extension DepositOfflineConfirmViewModel {
  func prepareForAppear(
    memo: OfflineDepositDTO.Memo,
    selectedBank: PaymentsDTO.BankCard)
  {
    receiverInfo = .init(
      identity: memo.identity,
      bank: selectedBank.name,
      bankImage: bankIconName(selectedBank.bankId),
      branch: memo.beneficiary.branch,
      receiver: memo.beneficiary.account.accountName,
      bankAccount: memo.beneficiary.account.accountNumber,
      validTimeLeftHour: memo.expiredHour)

    remitTip = .init(
      name: memo.remitter.name,
      amountAttributedString: amountAttributed(from: memo.remittance.formatString()))
  }

  func startCounting() {
    Observable<Int>
      .interval(.seconds(1), scheduler: MainScheduler.instance)
      .map { [unowned self] in Int(self.receiverInfo.validTimeLeftHour) * 3600 - 1 - $0 }
      .startWith(Int(self.receiverInfo.validTimeLeftHour) * 3600)
      .take(
        until: { $0 <= 0 },
        behavior: .inclusive)
      .subscribe(onNext: { [unowned self] in
        self.validTimeString = self.configTimeString($0)
      }, onDisposed: { [weak self] in
        self?.expiredSubject.onNext(())
      })
      .disposed(by: disposeBag)
  }

  func amountAttributed(from amountString: String) -> NSAttributedString {
    let split = amountString.split(separator: ".")

    let result = amountString
      .attributed
      .textColor(.whitePure)
      .font(weight: .semibold, locale: locale, size: 24)

    if split.count > 1 {
      result
        .highlights(
          weight: .semibold,
          locale: locale,
          size: 24,
          color: .orangeFF8000,
          subStrings: ["\(split.last ?? "")"],
          skip: "\(split.first ?? "")")
    }

    return result
  }

  func bankIconName(_ bankId: String) -> String? {
    switch locale {
    case is SupportLocale.China:
      return "CNY-\(bankId)"
    case is SupportLocale.Vietnam:
      return "VND-\(bankId)"
    default:
      return nil
    }
  }

  func configTimeString(_ seconds: Int) -> String {
    let hour = seconds / 3600
    let minute = seconds % 3600 / 60
    let second = seconds % 60

    if hour < 1 {
      return String(format: "%02d:%02d", minute, second)
    }
    else {
      return String(format: "%02d:%02d:%02d", hour, minute, second)
    }
  }
}

// MARK: - Model

struct DepositOfflineConfirmModel {
  struct ReceiverInfo {
    var identity = ""
    var bank = "-"
    var bankImage: String?
    var branch = "-"
    var receiver = "-"
    var bankAccount = "-"
    var validTimeLeftHour: Int64 = -1
  }

  struct RemitTip {
    var name = "-"
    var amountAttributedString: NSAttributedString = "-".attributed.textColor(.whitePure)
  }
}
