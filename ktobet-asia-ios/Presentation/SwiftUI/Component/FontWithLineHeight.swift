import sharedbu
import SwiftUI

struct FontWithLineHeight: ViewModifier {
  @Environment(\.playerLocale) var playerLocale: SupportLocale

  let fontWeight: KTOFontWeight
  let size: CGFloat
  let lineHeight: CGFloat

  func body(content: Content) -> some View {
    content
      .font(.custom(fontWeight.fontString(playerLocale), size: size))
      .lineSpacing(lineHeight - (UIFont(name: fontWeight.fontString(playerLocale), size: size)?.lineHeight ?? 0))
      .padding(
        .vertical,
        (lineHeight - (UIFont(name: fontWeight.fontString(playerLocale), size: size)?.lineHeight ?? 0)) / 2)
  }
}

extension View {
  func fontWithLineHeight(
    font: KTOFontWeight,
    size: CGFloat,
    lineHeight: CGFloat) -> some View {
    ModifiedContent(content: self, modifier: FontWithLineHeight(fontWeight: font, size: size, lineHeight: lineHeight))
  }
}

struct FontWithLineHeight_Previews: PreviewProvider {
  static var previews: some View {
    Text("你好")
      .fontWithLineHeight(font: .medium, size: 12, lineHeight: 24)
      .background(Color.red)
  }
}
