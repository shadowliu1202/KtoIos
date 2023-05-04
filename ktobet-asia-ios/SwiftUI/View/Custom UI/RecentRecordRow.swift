import SwiftUI
import UIKit

struct RecentRecordRow: View {
  private let date: String
  private let statusTitle: String
  private let statusColor: UIColor
  private let id: String
  private let amount: String
  private let isLastCell: Bool

  init(
    date: String,
    statusTitle: String,
    statusColor: UIColor,
    id: String,
    amount: String,
    isLastCell: Bool)
  {
    self.date = date
    self.statusTitle = statusTitle
    self.statusColor = statusColor
    self.id = id
    self.amount = amount
    self.isLastCell = isLastCell
  }

  var body: some View {
    VStack(spacing: 9) {
      HStack(alignment: .top, spacing: 8) {
        Text(date)
          .localized(weight: .medium, size: 12, color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(statusTitle)
          .multilineTextAlignment(.trailing)
          .localized(weight: .regular, size: 14, color: statusColor)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }

      HStack(spacing: 8) {
        Text(id)
          .localized(weight: .medium, size: 14, color: .whitePure)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(amount)
          .multilineTextAlignment(.trailing)
          .localized(weight: .regular, size: 14, color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 16)
    .backgroundColor(.gray1A1A1A)
    .overlay(
      Separator(color: .gray3C3E40)
        .visibility(
          isLastCell ? .gone : .visible),
      alignment: .bottom)
  }
}

struct WalletRecentRecordCell_Previews: PreviewProvider {
  static var previews: some View {
    RecentRecordRow(
      date: "2019/10/09 22:43:08",
      statusTitle: "需上传交易资讯",
      statusColor: .orangeFF8000,
      id: "PWCMQ1338287752",
      amount: "100.05",
      isLastCell: false)
  }
}
