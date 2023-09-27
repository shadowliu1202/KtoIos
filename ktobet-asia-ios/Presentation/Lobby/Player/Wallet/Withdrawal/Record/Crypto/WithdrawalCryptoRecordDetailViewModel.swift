import Foundation
import RxSwift
import SharedBu

protocol WithdrawalCryptoRecordDetailViewModelProtocol: CryptoRecordDetailViewModel {
  func getLog(displayId: String)
  func generateRecords(_ data: WithdrawalDto.CryptoLog) -> [CryptoRecord]
}

extension WithdrawalCryptoRecordDetailViewModelProtocol {
  func generateRecords(_ data: WithdrawalDto.CryptoLog) -> [CryptoRecord] {
    let log = data.log
    let isTransactionComplete = data.isTransactionComplete
    let processingMemo = data.processingMemo
    let fiatSimpleName = processingMemo.request.toFiatSimpleName

    return [
      .info(.init(
        title: Localize.string("balancelog_detail_id"),
        content: log.displayId)),
      .info(.init(
        title: Localize.string("common_status"),
        content: log.status.toString())),
      .table(
        [
          .init(title: Localize.string("common_cps_apply_info")),
          .init(
            title: Localize.string("common_cps_apply_crypto"),
            content: processingMemo.requestFromCrypto),
          .init(
            title: Localize.string("common_cps_apply_rate"),
            content: processingMemo.requestRate),
          .init(
            title: Localize.string("common_cps_apply_amount", fiatSimpleName),
            content: processingMemo.requestFiatFormat),
          .init(
            title: Localize.string("common_applytime"),
            content: processingMemo.requestDateTimeString)
        ],
        [
          .init(title: Localize.string("common_cps_final_info")),
          .init(
            title: Localize.string("common_cps_final_crypto"),
            content: processingMemo.actualFromCrypto(isTransactionComplete),
            contentColor: data.log.status == .approved ? .alert : .greyScaleWhite),
          .init(
            title: Localize.string("common_cps_final_rate"),
            content: processingMemo.actualRate(isTransactionComplete)),
          .init(
            title: Localize.string("common_cps_final_amount", fiatSimpleName),
            content: processingMemo.actualToFiatFormat(isTransactionComplete)),
          .init(
            title: Localize.string("common_cps_final_datetime"),
            content: processingMemo.actualDateTimeString(isTransactionComplete))
        ]),
      .info(.init(
        title: Localize.string("common_cps_remitter", Localize.string("cps_kto")),
        content: processingMemo.remitterAddress)),
      .info(.init(
        title: Localize.string("common_cps_payee", Localize.string("common_player")),
        content: processingMemo.payeeAddress)),
      .info(.init(
        title: Localize.string("common_cps_hash_id"),
        content: processingMemo._hashId)),
      .remark(.init(
        title: Localize.string("common_remark"),
        content: generateRemarkContent(data.updateHistories),
        date: generateRemarkDate(data.updateHistories)))
    ]
  }

  private func generateRemarkContent(_ histories: [UpdateHistory]?) -> [String]? {
    histories?.map({ $0.remarkLevel1 + " > " + $0.remarkLevel2 + " > " + $0.remarkLevel3 })
  }

  private func generateRemarkDate(_ histories: [UpdateHistory]?) -> [String]? {
    histories?.map { $0.createdDate.toDateTimeString() }
  }
}

class WithdrawalCryptoRecordDetailViewModel:
  CollectErrorViewModel,
  WithdrawalCryptoRecordDetailViewModelProtocol,
  ObservableObject
{
  @Published private(set) var header: CryptoRecordHeader?
  @Published private(set) var info: [CryptoRecord]?

  private let appService: IWithdrawalAppService
  private let disposeBag = DisposeBag()

  init(appService: IWithdrawalAppService) {
    self.appService = appService
  }

  func getLog(displayId: String) {
    Observable.from(
      appService.getCryptoLog(displayId: displayId))
      .compose(applyObservableErrorHandle())
      .subscribe(onNext: { [weak self] in
        self?.header = .init(
          fromCryptoName: $0.processingMemo.request?.fromCrypto.simpleName,
          showUnCompleteHint: $0.log.status != .approved)
        self?.info = self?.generateRecords($0)
      })
      .disposed(by: disposeBag)
  }
}

extension String {
  fileprivate func replaceEmpty() -> String {
    self.isEmpty ? "-" : self
  }
}

extension WithdrawalDto.ProcessingMemo {
  fileprivate var remitterAddress: String {
    self.fromWalletAddress.replaceEmpty()
  }

  fileprivate var payeeAddress: String {
    self.toWalletAddress.replaceEmpty()
  }

  fileprivate var _hashId: String {
    self.hashId.replaceEmpty()
  }

  fileprivate var requestFromCrypto: String {
    self.request.fromCrypto
  }

  fileprivate var requestRate: String {
    self.request.rate
  }

  fileprivate var requestFiatFormat: String {
    self.request.fiatFormat
  }

  fileprivate var requestDateTimeString: String {
    self.request.dateTimeString
  }

  fileprivate func actualFromCrypto(_ isTransactionComplete: Bool) -> String {
    self.actual.fromCrypto(isTransactionComplete)
  }

  fileprivate func actualRate(_ isTransactionComplete: Bool) -> String {
    self.actual.rate(isTransactionComplete)
  }

  fileprivate func actualToFiatFormat(_ isTransactionComplete: Bool) -> String {
    self.actual.toFiatFormat(isTransactionComplete)
  }

  fileprivate func actualDateTimeString(_ isTransactionComplete: Bool) -> String {
    self.actual.dateTimeString(isTransactionComplete)
  }
}

extension Optional where Wrapped: ExchangeMemo {
  fileprivate func replaceEmpty(from: String?, condition: Bool = true) -> String {
    if condition {
      return from.isNullOrEmpty() ? "-" : from!
    }
    else {
      return "-"
    }
  }

  fileprivate var fromCrypto: String {
    replaceEmpty(
      from: self?.fromCrypto.formatString(),
      condition: self?.fromCrypto.abs().formatString() != "0")
  }

  fileprivate var rate: String {
    replaceEmpty(
      from: self?.rate.formatString(),
      condition: self?.rate.formatString() != "0")
  }

  fileprivate var fiatFormat: String {
    replaceEmpty(
      from: self?.toFiat.formatString(),
      condition: self?.toFiat.abs().formatString() != "0")
  }

  fileprivate var dateTimeString: String {
    replaceEmpty(from: self?.date.toDateTimeString())
  }

  fileprivate func fromCrypto(_ isTransactionComplete: Bool) -> String {
    replaceEmpty(
      from: self?.fromCrypto.formatString(),
      condition: isTransactionComplete)
  }

  fileprivate func rate(_ isTransactionComplete: Bool) -> String {
    replaceEmpty(
      from: self?.rate.formatString(),
      condition: isTransactionComplete)
  }

  fileprivate func toFiatFormat(_ isTransactionComplete: Bool) -> String {
    replaceEmpty(
      from: self?.toFiat.formatString(),
      condition: isTransactionComplete)
  }

  fileprivate func dateTimeString(_ isTransactionComplete: Bool) -> String {
    replaceEmpty(
      from: self?.date.toDateTimeString(),
      condition: isTransactionComplete)
  }
}
