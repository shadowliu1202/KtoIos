import SwiftUI

protocol RemarkRowModel {
    var title: String { get }
    var date: [String]? { get }
    var content: [String]? { get }
}

extension RemarkRowModel {
    var title: String { "" }
    var date: [String]? { nil }
    var content: [String]? { nil }
    var contentTuple: [(String, String)]? {
        guard let date, let content, date.count == content.count else {
            return nil
        }
        var tuples = [(String, String)]()
        for (index, _date) in date.enumerated() {
            tuples.append((_date, content[index]))
        }
        return tuples
    }
}

@available(*, deprecated)
struct RemarkRow: View {
    struct Remark: RemarkRowModel {
        var title: String
        var date: [String]?
        var content: [String]?
    }

    let model: RemarkRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.title)
                .localized(weight: .regular, size: 12, color: .textPrimary)

            if let content = model.contentTuple {
                ForEach(content.indices, id: \.self) {
                    let date = content[$0].0
                    let str = content[$0].1
                    Text(date)
                        .localized(weight: .regular, size: 12, color: .textPrimary)
                    LimitSpacer(2)
                    Text(str)
                        .localized(weight: .regular, size: 16, color: .greyScaleWhite)
                    LimitSpacer(18)
                        .visibility(($0 == content.count - 1) ? .gone : .visible)
                }
            }
        }
    }
}

struct RemarkRow_Previews: PreviewProvider {
    static var previews: some View {
        RemarkRow(
            model:
            RemarkRow.Remark(
                title: "Mark",
                date: ["2023/01/06", "2022/12/14"],
                content: ["1 > 2 > 3", "3 > 4 > 5"]))
            .backgroundColor(.greyScaleDefault)
    }
}
