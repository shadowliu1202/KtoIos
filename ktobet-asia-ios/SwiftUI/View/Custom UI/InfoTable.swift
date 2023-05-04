import SwiftUI

struct InfoTable: View {
  let applyInfo: [DefaultRowModel]?
  let finallyInfo: [DefaultRowModel]?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if let applyInfo, let finallyInfo {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(applyInfo.indices, id: \.self) {
            let record = applyInfo[$0]

            if $0 == 0 {
              Text(record.title ?? "")
                .localized(weight: .medium, size: 16, color: .gray9B9B9B)
            }
            else {
              DefaultRow(model: record)
            }
          }
        }

        Separator(color: .gray3C3E40)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(finallyInfo.indices, id: \.self) {
            let record = finallyInfo[$0]

            if $0 == 0 {
              Text(record.title ?? "")
                .localized(weight: .medium, size: 16, color: .gray9B9B9B)
            }
            else {
              DefaultRow(model: record)
            }
          }
        }
      }
      else {
        EmptyView()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .stroke(color: .gray3C3E40, cornerRadius: 0)
  }
}

struct InfoTable_Previews: PreviewProvider {
  struct Head: DefaultRowModel {
    var title: String? = "Section"
    var content: String? = "HeadContent"
    var contentColor: UIColor? = .gray9B9B9B
  }

  struct Item: DefaultRowModel {
    var title: String? = "Row"
    var content: String? = "RowContent"
    var contentColor: UIColor? = .whitePure
  }

  static var previews: some View {
    InfoTable(
      applyInfo: [Head(), Item()],
      finallyInfo: [Head(), Item()])
      .backgroundColor(.gray131313)
  }
}
