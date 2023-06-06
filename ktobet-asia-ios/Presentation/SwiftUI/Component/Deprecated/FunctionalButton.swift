import SwiftUI

let FunctionalButton_Content_ID = "FunctionalButton_Content_ID"

@available(*, deprecated)
struct FunctionalButton<Content: View>: View {
  private let imageName: String
  private let content: Content
  private let borderPadding: CGFloat
  private let action: (() -> Void)?

  init(
    imageName: String,
    @ViewBuilder content: () -> Content,
    borderPadding: CGFloat = 12,
    action: (() -> Void)?)
  {
    self.imageName = imageName
    self.content = content()
    self.borderPadding = borderPadding
    self.action = action
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(imageName)
        .resizable()
        .frame(width: 24, height: 24)
        .foregroundColor(.from(.textPrimary))

      HStack(spacing: 0) {
        content
          .frame(
            maxWidth: .infinity,
            alignment: .leading)
          .id("FunctionalButton_Content_ID")
      }

      Image("iconChevronRight16")
        .resizable()
        .frame(width: 16, height: 16)
    }
    .padding(borderPadding)
    .stroke(
      color: .textPrimary,
      cornerRadius: 8,
      lineWidth: 0.5)
    .contentShape(Rectangle())
    .onTapGesture {
      action?()
    }
  }
}

struct FunctionalButton_Previews: PreviewProvider {
  static var previews: some View {
    FunctionalButton(
      imageName: "icon.filter",
      content: {
        Text("HI")
      },
      action: { })
  }
}
