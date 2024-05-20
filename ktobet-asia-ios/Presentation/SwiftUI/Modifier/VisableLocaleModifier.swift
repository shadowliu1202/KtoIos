import sharedbu
import SwiftUI

struct VisibleLocaleModifier: ViewModifier {
    private let availableLocales: [SupportLocale]
    private let currentLocale: SupportLocale
  
    init(
        availableLocales: [SupportLocale],
        currentLocale: SupportLocale)
    {
        self.availableLocales = availableLocales
        self.currentLocale = currentLocale
    }

    func body(content: Content) -> some View {
        if availableLocales.contains(where: { $0.self == currentLocale.self }) {
            content
        }
        else {
            EmptyView()
        }
    }
}

extension View {
    func visibleLocale(availableLocales: SupportLocale..., currentLocale: SupportLocale) -> some View {
        self.modifier(VisibleLocaleModifier(availableLocales: availableLocales, currentLocale: currentLocale))
    }
}
