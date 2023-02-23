import SwiftUI

struct WithdrawalCryptoDetailRowView: View {
  var title = ""
  var content = ""
  var isShowBottomDivider = true
  var contentColor = Color(.whitePure)

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer().frame(height: 8.5)

      Text(title)
        .foregroundColor(Color(UIColor.gray9B9B9B))
        .font(Font.custom("PingFangSC-Regular", size: 12))

      Spacer().frame(height: 2)

      Text(content.isEmpty || content == "0" ? "-" : content)
        .foregroundColor(contentColor)
        .font(Font.custom("PingFangSC-Regular", size: 16))

      if isShowBottomDivider {
        Spacer().frame(height: 8.5)
        Divider()
          .frame(height: 1)
          .background(Color(UIColor.gray3C3E40))
      }
    }
    .background(Color(.black131313))
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct WithdrawalCryptoDetailRowView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      WithdrawalCryptoDetailRowView(
        title: Localize.string("balancelog_detail_id"),
        content: Localize.string("balancelog_detail_id"))
      WithdrawalCryptoDetailRowView(title: Localize.string("common_status"), content: Localize.string("common_status"))
    }
    .previewLayout(.fixed(width: 300, height: 60))
  }
}
