import Foundation
import RxSwift
import sharedbu

protocol CryptoRecordDetailViewModel {
  var header: CryptoRecordHeader? { get }
  var info: [CryptoRecord]? { get }
}

struct CryptoRecordHeader {
  var fromCryptoName: String?
  var showUnCompleteHint: Bool
}

enum CryptoRecord: Equatable {
  struct Item: DefaultRowModel {
    var title: String?
    var content: String?
    var contentColor: UIColor = .greyScaleWhite
  }

  struct LinkItem: LinkRowModel {
    var title: String?
    var content: String?
    var attachment: String
    var clickAttachment: (() -> Void)?
  }

  struct Remark: RemarkRowModel {
    var title: String
    var content: [String]?
    var date: [String]?
  }

  case info(Item)
  case link(LinkItem)
  case remark(Remark)
  case table([Item], [Item])

  static func == (lhs: CryptoRecord, rhs: CryptoRecord) -> Bool {
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

extension Optional where Wrapped: ExchangeMemo {
  var toFiatSimpleName: String {
    self?.toFiat.simpleName ?? "-"
  }
}
