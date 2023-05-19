import SwiftUI

protocol LogRowModel {
  var createdDateText: String { get }
  var statusConfig: (text: String, color: UIColor)? { get }
  var displayId: String { get }
  var amountConfig: (text: String, color: UIColor) { get }
}

@available(*, deprecated, message: "Waiting for refactor.")
struct LogRow: View {
  let model: LogRowModel

  var onSelected: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(model.createdDateText)
        .localized(
          weight: .medium,
          size: 12,
          color: .textPrimary)
        .applyTransform(when: model.statusConfig != nil) { contentView in
          HStack(alignment: .top) {
            contentView

            Spacer(minLength: 8)

            Text(model.statusConfig?.text ?? "")
              .localized(
                weight: .regular,
                size: 14,
                color: model.statusConfig?.color ?? .clear)
          }
        }

      HStack {
        Text(model.displayId)
          .localized(
            weight: .medium,
            size: 14,
            color: .greyScaleWhite)

        Spacer(minLength: 8)

        Text(model.amountConfig.text)
          .localized(
            weight: .regular,
            size: 14,
            color: model.amountConfig.color)
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .backgroundColor(.inputDefault)
    .cornerRadius(8)
    .onTapGesture {
      onSelected?()
    }
  }
}

struct LogRow_Preview: PreviewProvider {
  struct Dummy: LogRowModel {
    let createdDateText = "123456"
    var statusConfig: (text: String, color: UIColor)? = ("Text", .yellow)
    var amountConfig: (text: String, color: UIColor) = ("100", .gray)
    let displayId = "aaa"
  }

  static var previews: some View {
    LogRow(model: Dummy())

    LogRow(model: Dummy(statusConfig: nil))
  }
}
