import SwiftUI

protocol LinkRowModel: DefaultRowModel {
  var attachment: String { get }
  var clickAttachment: (() -> Void)? { get }
}

struct LinkRow: View {
  struct LinkModel: LinkRowModel {
    var title: String?
    var content: String?
    var attachment: String
    var clickAttachment: (() -> Void)?
  }

  let model: LinkRowModel

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      DefaultRow(model: model)

      Text(model.attachment)
        .underline(true, color: .from(.redF20000))
        .localized(weight: .regular, size: 16, color: .redF20000)
        .onTapGesture {
          model.clickAttachment?()
        }
    }
  }
}

struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    LinkRow(model: LinkRow.LinkModel(
      title: "Test",
      content: "Content",
      attachment: "url_Link"))
      .backgroundColor(.gray131313)
  }
}
