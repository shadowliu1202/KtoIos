import sharedbu
import SwiftUI

struct LocalizeFont<Content: View>: View {
  @Environment(\.playerLocale) var playerLocale: SupportLocale

  let fontWeight: KTOFontWeight
  let size: CGFloat
  let color: UIColor
  let lineHeight: CGFloat?

  var content: Content

  init(
    fontWeight: KTOFontWeight,
    size: CGFloat,
    color: UIColor,
    lineHeight: CGFloat?,
    @ViewBuilder content: () -> Content)
  {
    self.fontWeight = fontWeight
    self.size = size
    self.color = color
    self.lineHeight = lineHeight
    self.content = content()
  }

  var body: some View {
    if let lineHeight {
      content
        .font(.custom(fontWeight.fontString(playerLocale), size: size))
        .foregroundColor(.from(color))
        .lineSpacing(lineHeight - (UIFont(name: fontWeight.fontString(playerLocale), size: size)?.lineHeight ?? 0))
        .padding(
          .vertical,
          (lineHeight - (UIFont(name: fontWeight.fontString(playerLocale), size: size)?.lineHeight ?? 0)) / 2)
    }
    else {
      content
        .font(.custom(fontWeight.fontString(playerLocale), size: size))
        .foregroundColor(.from(color))
    }
  }
}

struct FontAndColor_Previews: PreviewProvider {
  static var previews: some View {
    LocalizeFont(fontWeight: .medium, size: 12, color: .textPrimary, lineHeight: 24) {
      Text("你好")
    }
  }
}

extension View {
  func localized(
    weight: KTOFontWeight,
    size: CGFloat,
    // KTO-4957 [iOS] 修改localize修飾器預設的顏色
    color: UIColor = UIColor(.black.opacity(0.00001)),
    lineHeight: CGFloat? = nil)
    -> some View
  {
    LocalizeFont(
      fontWeight: weight,
      size: size,
      color: color,
      lineHeight: lineHeight) { self }
  }
}
