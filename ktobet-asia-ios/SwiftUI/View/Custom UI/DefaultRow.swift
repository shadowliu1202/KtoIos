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
  var contentColor: UIColor { .whitePure }
}

struct DefaultRow: View {
  struct Common: DefaultRowModel {
    var title: String?
    var date: String?
    var content: String?
    var contentColor: UIColor = .whitePure
  }

  let model: DefaultRowModel
  let contentLineLimit: Int?

  init(model: DefaultRowModel, contentLineLimit: Int? = 2) {
    self.model = model
    self.contentLineLimit = contentLineLimit
  }

  init(common: Common, contentLineLimit: Int? = 2) {
    self.model = common
    self.contentLineLimit = contentLineLimit
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(model.title ?? "")
        .localized(
          weight: .regular,
          size: 12,
          color: .gray9B9B9B)
        .frame(maxWidth: .infinity, alignment: .leading)
        .visibility(model.title == nil ? .gone : .visible)

      Text(model.date ?? "")
        .localized(
          weight: .regular,
          size: 12,
          color: .gray9B9B9B)
        .frame(maxWidth: .infinity, alignment: .leading)
        .visibility(model.date == nil ? .gone : .visible)

      Text(model.content ?? "")
        .localized(
          weight: .regular,
          size: 16,
          color: model.contentColor)
        .lineLimit(contentLineLimit)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
