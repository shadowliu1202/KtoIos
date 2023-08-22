import SwiftUI

protocol DefaultRowModel {
  var title: String? { get }
  var date: String? { get }
  var content: String? { get }
  var contentColor: UIColor { get }
}

extension DefaultRowModel {
  var title: String? { nil }
  var date: String? { nil }
  var content: String? { nil }
  var contentColor: UIColor { .greyScaleWhite }
}

@available(*, deprecated)
struct DefaultRow: View {
  struct Common: DefaultRowModel {
    var title: String?
    var date: String?
    var content: String?
    var contentColor: UIColor = .greyScaleWhite
  }

  let model: DefaultRowModel

  init(model: DefaultRowModel) {
    self.model = model
  }

  init(common: Common) {
    self.model = common
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(model.title ?? "")
        .localized(
          weight: .regular,
          size: 12,
          color: .textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .visibility(model.title == nil ? .gone : .visible)

      Text(model.date ?? "")
        .localized(
          weight: .regular,
          size: 12,
          color: .textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .visibility(model.date == nil ? .gone : .visible)

      Text(model.content ?? "")
        .localized(
          weight: .regular,
          size: 16,
          color: model.contentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
