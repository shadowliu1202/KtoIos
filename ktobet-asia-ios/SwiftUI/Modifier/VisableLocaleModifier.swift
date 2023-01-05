import SwiftUI
import SharedBu

struct VisableLocaleModifier: ViewModifier {
    @Environment(\.playerLocale) var currentLocale: SupportLocale
    
    let locales: [SupportLocale]
    
    func body(content: Content) -> some View {
        if locales.contains(where: { $0.self == currentLocale.self }) {
            content
        }
        else {
            EmptyView()
        }
    }
}

extension View {
    
    func visableLocale(_ locales: [SupportLocale]) -> some View {
        self.modifier(VisableLocaleModifier(locales: locales))
    }
}
