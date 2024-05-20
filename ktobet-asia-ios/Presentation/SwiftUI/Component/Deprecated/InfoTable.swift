import SwiftUI

@available(*, deprecated)
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
                                .localized(weight: .medium, size: 16, color: .textPrimary)
                        }
                        else {
                            DefaultRow(model: record)
                        }
                    }
                }

                Separator()

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(finallyInfo.indices, id: \.self) {
                        let record = finallyInfo[$0]

                        if $0 == 0 {
                            Text(record.title ?? "")
                                .localized(weight: .medium, size: 16, color: .textPrimary)
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
        .stroke(color: .greyScaleDivider, cornerRadius: 0)
    }
}

struct InfoTable_Previews: PreviewProvider {
    struct Head: DefaultRowModel {
        var title: String? = "Section"
        var content: String? = "HeadContent"
        var contentColor: UIColor? = .textPrimary
    }

    struct Item: DefaultRowModel {
        var title: String? = "Row"
        var content: String? = "RowContent"
        var contentColor: UIColor? = .greyScaleWhite
    }

    static var previews: some View {
        InfoTable(
            applyInfo: [Head(), Item()],
            finallyInfo: [Head(), Item()])
            .backgroundColor(.greyScaleDefault)
    }
}
