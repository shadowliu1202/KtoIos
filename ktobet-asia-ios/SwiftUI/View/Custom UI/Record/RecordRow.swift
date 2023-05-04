import SwiftUI

struct RecordRow: View {
  enum `Type` {
    case amount(_ content: String?)
    case status(date: String?, content: String?)
    case applyDate(_ content: String?)
    case depositId(_ content: String?)
    case withdrawalId(_ content: String?)
    case remark(_ config: RecordRemark.Configuration)
  }

  let type: `Type`
  let shouldShowBottomLine: Bool
  let shouldShowUploader: Bool

  var body: some View {
    VStack(spacing: 8) {
      switch type {
      case .amount(let content):
        DefaultRow(common: .init(
          title: Localize.string("common_transactionamount"),
          content: content))
      case .status(let date, let content):
        DefaultRow(common: .init(
          title: Localize.string("common_status"),
          date: date,
          content: content))
      case .applyDate(let content):
        DefaultRow(common: .init(
          title: Localize.string("common_applytime"),
          content: content))
      case .depositId(let content):
        DefaultRow(common: .init(
          title: Localize.string("deposit_ticketnumber"),
          content: content))
      case .withdrawalId(let content):
        DefaultRow(common: .init(
          title: Localize.string("withdrawal_id"),
          content: content))
      case .remark(let config):
        RecordRemark(config: config, shouldShowUploader: shouldShowUploader)
      }

      Separator(color: .gray3C3E40)
        .visibility(shouldShowBottomLine ? .visible : .gone)
    }
  }
}
