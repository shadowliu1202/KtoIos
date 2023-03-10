import Foundation
import RxSwift
import SharedBu

protocol DepositCryptoRecordDetailViewModelProtocol {
  var header: DepositCryptoRecordHeader? { get }
  var info: [DepositCryptoRecord]? { get }

  func getDepositCryptoLog(transactionId: String)
}

struct DepositCryptoRecordHeader {
  var fromCryptoName: String?
  var showInCompleteHint: Bool
}

enum DepositCryptoRecord: Equatable {
  struct Item {
    var title: String
    var content: String?
    var contentColor: UIColor?
    var attachment: String?
    var updateUrl: SingleWrapper<HttpUrl>?
  }

  struct Remark {
    var title: String
    var content: [String]?
    var date: String?
  }

  case info(Item)
  case link(Item)
  case remark(Remark)
  case table([Item], [Item])

  static func == (lhs: DepositCryptoRecord, rhs: DepositCryptoRecord) -> Bool {
    switch (lhs, rhs) {
    case (.info, .info),
         (.link, .link),
         (.remark, .remark),
         (.table, .table):
      return true
    default:
      return false
    }
  }
}
