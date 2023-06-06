import SharedBu
import SwiftUI

struct LocalizeFont<Content: View>: View {
  @Environment(\.playerLocale) var playerLocale: SupportLocale

  let fontWeight: KTOFontWeight
  let size: CGFloat
  let color: UIColor

  var content: Content

  init(fontWeight: KTOFontWeight, size: CGFloat, color: UIColor, @ViewBuilder content: () -> Content) {
    self.fontWeight = fontWeight
    self.size = size
    self.color = color
    self.content = content()
  }

  var body: some View {
    content
      .font(.custom(fontWeight.fontString(playerLocale), size: size))
      .foregroundColor(.from(color))
  }
}

struct FontAndColor_Previews: PreviewProvider {
  static var previews: some View {
    LocalizeFont(fontWeight: .medium, size: 12, color: .textPrimary) {
      Text("你好")
    }
  }
}

extension View {
  func localized(
    weight: KTOFontWeight,
    size: CGFloat,
    // KTO-4957 [iOS] 修改localize修飾器預設的顏色
    color: UIColor = UIColor(.black.opacity(0.00001)))
    -> some View
  {
    LocalizeFont(
      fontWeight: weight,
      size: size,
      color: color) { self }
  }
}
