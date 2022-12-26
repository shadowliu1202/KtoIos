import SwiftUI
import SharedBu

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
        LocalizeFont(fontWeight: .medium, size: 12, color: .gray9B9B9B) {
            Text("你好")
        }
    }
}
