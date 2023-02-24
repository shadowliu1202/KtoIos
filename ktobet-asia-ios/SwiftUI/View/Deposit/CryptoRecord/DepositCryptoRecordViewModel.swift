import Foundation
import RxSwift
import SharedBu

class DepositCryptoRecordViewModel: CollectErrorViewModel,
  DepositCryptoRecordViewModelProtocol,
  ObservableObject
{
  private let depositService: IDepositAppService
  private let disposeBag = DisposeBag()

  @Published private(set) var header: DepositCryptoRecordHeader?
  @Published private(set) var info: [DepositCryptoRecord]?

  init(depositService: IDepositAppService) {
    self.depositService = depositService
  }

  func getDepositCryptoLog(transactionId: String) {
    Observable.from(
      depositService.getCryptoLog(displayId: transactionId))
      .subscribe(onNext: { [weak self] in
        self?.header = .init(
          fromCryptoName: $0.processingMemo.request?.fromCrypto.simpleName,
          showInCompleteHint: $0.log.status != .approved)
        self?.info = self?.generateRecords($0)
      })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension DepositCryptoRecordViewModel {
  func generateRecords(_ data: PaymentLogDTO.CryptoLog?) -> [DepositCryptoRecord] {
    let log = data?.log
    let isTransactionComplete = data?.isTransactionComplete ?? false
    let processingMemo = data?.processingMemo
    let requestMemo = processingMemo?.request

    var statusRow: DepositCryptoRecord
    if data?.log.status == .floating {
      statusRow = .link(
        .init(
          title: Localize.string("activity_status"),
          content: log.statusString,
          attachment: Localize.string("common_cps_submit_hash_id_to_complete"),
          updateUrl: data?.updateUrl))
    }
    else {
      statusRow = .info(
        .init(
          title: Localize.string("activity_status"),
          content: log.statusString))
    }

    return [
      DepositCryptoRecord.info(
        .init(
          title: Localize.string("balancelog_detail_id"),
          content: log._displayId)),
      statusRow,
      DepositCryptoRecord.table(
        [
          .init(title: Localize.string("common_cps_apply_info")),
          .init(
            title: Localize.string("common_cps_apply_crypto"),
            content: processingMemo.requestFromCrypto),
          .init(
            title: Localize.string("common_cps_apply_rate"),
            content: processingMemo.requestRate),
          .init(
            title: Localize.string("common_cps_apply_amount", requestMemo.toFiatSimpleName),
            content: processingMemo.requestFiatFormat),
          .init(
            title: Localize.string("common_applytime"),
            content: log.createDateTimeString)
        ],
        [
          .init(title: Localize.string("common_cps_final_info")),
          .init(
            title: Localize.string("common_cps_final_crypto"),
            content: processingMemo.actualFromCrypto(isTransactionComplete),
            contentColor: data?.log.status == .approved ? .orangeFF8000 : .whitePure),
          .init(
            title: Localize.string("common_cps_final_rate"),
            content: processingMemo.actualRate(isTransactionComplete)),
          .init(
            title: Localize.string("common_cps_final_amount", requestMemo.toFiatSimpleName),
            content: processingMemo.actualToFiatFormat(isTransactionComplete)),
          .init(
            title: Localize.string("common_cps_final_datetime"),
            content: processingMemo.actualDateTimeString(isTransactionComplete))
        ]),
      DepositCryptoRecord.info(
        .init(
          title: Localize.string("common_cps_remitter", Localize.string("common_player")),
          content: "-")),
      DepositCryptoRecord.info(
        .init(
          title: Localize.string("common_cps_payee", Localize.string("cps_kto")),
          content: processingMemo.address)),
      DepositCryptoRecord.info(
        .init(
          title: Localize.string("common_cps_hash_id"),
          content: processingMemo._hashId)),
      DepositCryptoRecord.remark(
        .init(
          title: Localize.string("common_remark"),
          content: generateRemarkContent(data?.updateHistories),
          date: log.updateTimeString))
    ]
  }

  private func generateRemarkContent(_ histories: [UpdateHistory]?) -> [String]? {
    histories?.map({ $0.remarkLevel1 + " > " + $0.remarkLevel2 + " > " + $0.remarkLevel3 })
  }
}

extension Optional where Wrapped: PaymentLogDTO.Log {
  fileprivate var statusString: String {
    self?.status.toLogString() ?? ""
  }

  fileprivate var _displayId: String {
    self?.displayId ?? ""
  }

  fileprivate var createDateTimeString: String {
    self?.createdDate.toDateTimeString() ?? "-"
  }

  fileprivate var updateTimeString: String? {
    self?.updateDate.toDateTimeString()
  }
}

extension Optional where Wrapped: PaymentLogDTO.ProcessingMemo {
  fileprivate var address: String {
    self?.toAddress ?? "-"
  }

  fileprivate var _hashId: String {
    self?.hashId.isEmpty ?? true ? "-" : self!.hashId
  }

  fileprivate var requestFromCrypto: String {
    if self?.request?.fromCrypto.formatString(.none) != "0" {
      return self?.request?.fromCrypto.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate var requestRate: String {
    if self?.request?.rate.formatString() != "0" {
      return self?.request?.rate.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate var requestFiatFormat: String {
    if self?.request?.toFiat.formatString(.none) != "0" {
      return self?.request?.toFiat.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate func actualFromCrypto(_ isTransactionComplete: Bool) -> String {
    if isTransactionComplete {
      return self?.actual?.fromCrypto.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate func actualRate(_ isTransactionComplete: Bool) -> String {
    if isTransactionComplete {
      return self?.actual?.rate.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate func actualToFiatFormat(_ isTransactionComplete: Bool) -> String {
    if isTransactionComplete {
      return self?.actual?.toFiat.formatString() ?? ""
    }
    else {
      return "-"
    }
  }

  fileprivate func actualDateTimeString(_ isTransactionComplete: Bool) -> String {
    if isTransactionComplete {
      return self?.actual?.date.toDateTimeString() ?? ""
    }
    else {
      return "-"
    }
  }
}

extension Optional where Wrapped: ExchangeMemo {
  fileprivate var toFiatSimpleName: String {
    self?.toFiat.simpleName ?? "-"
  }
}
