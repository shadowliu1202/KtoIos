import sharedbu
import SwiftUI

@available(*, deprecated, message: "Use native CustomFontModifier")
struct LocalizeFont<Content: View>: View {
    @Environment(\.playerLocale) var playerLocale: SupportLocale

    let fontWeight: KTOFontWeight
    let size: CGFloat
    let color: UIColor?

    var content: Content

    init(
        fontWeight: KTOFontWeight,
        size: CGFloat,
        color: UIColor?,
        @ViewBuilder content: () -> Content)
    {
        self.fontWeight = fontWeight
        self.size = size
        self.color = color
        self.content = content()
    }

    var body: some View {
        if let color {
            content
                .font(.custom(fontWeight.fontString(playerLocale), size: size))
                .foregroundColor(.from(color))
        }
        else {
            content
                .font(.custom(fontWeight.fontString(playerLocale), size: size))
        }
    }
}

extension View {
    @available(*, deprecated, message: "Use font extension")
    func localized(
        weight: KTOFontWeight,
        size: CGFloat,
        // KTO-4957 [iOS] 修改localize修飾器預設的顏色
        color: UIColor? = UIColor(.black.opacity(0.00001)))
        -> some View
    {
        LocalizeFont(
            fontWeight: weight,
            size: size,
            color: color
        ) { self }
    }
}

@available(*, deprecated, message: "Use font extension")
struct FontAndColor_Previews: PreviewProvider {
    static var previews: some View {
        LocalizeFont(fontWeight: .medium, size: 12, color: .textPrimary) {
            Text("你好")
        }
    }
}


struct CustomFontModifier: ViewModifier {
    @Environment(\.locale) var locale: Locale

    let fontWeight: KTOFontWeight
    let size: CGFloat

    func body(content: Content) -> some View {
        content.font(.custom(fontWeight.fontString(SupportLocale.companion.create(language: locale.identifier)), size: size))
    }
}

extension View {
    func font(weight: KTOFontWeight = .regular, size: CGFloat = 16) ->  some View {
        modifier(CustomFontModifier(fontWeight: weight, size: size))
    }
}
