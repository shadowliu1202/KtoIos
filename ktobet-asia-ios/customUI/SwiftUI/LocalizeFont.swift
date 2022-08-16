import SwiftUI
import SharedBu

struct LocalizeFont<Content: View>: View {
    @Environment(\.playerLocale) var playerLocale: SupportLocale
    
    let fontWeight: KTOFontWeight
    let size: CGFloat
    let color: KTOTextColor?
    
    var content: Content
    
    init(fontWeight: KTOFontWeight, size: CGFloat, color: KTOTextColor?, @ViewBuilder content: () -> Content) {
        self.fontWeight = fontWeight
        self.size = size
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        switch playerLocale {
        case is SupportLocale.Vietnam:
            content
                .font(.custom("HelveticaNeue-\(fontWeight.getSuffix(playerLocale))", size: size))
                .foregroundColor(color?.value)
        case is SupportLocale.China:
            content
                .font(.custom("PingFangSC-\(fontWeight.getSuffix(playerLocale))", size: size))
                .foregroundColor(color?.value)
        default:
            content
                .font(.custom("PingFangSC-\(fontWeight.getSuffix(playerLocale))", size: size))
                .foregroundColor(color?.value)
        }
    }
}

struct FontAndColor_Previews: PreviewProvider {
    static var previews: some View {
        LocalizeFont(fontWeight: .medium, size: 12, color: .primaryGray) {
            Text("你好")
        }
    }
}
