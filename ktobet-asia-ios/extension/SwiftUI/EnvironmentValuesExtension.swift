import SwiftUI
import SharedBu

private struct supportLocale: EnvironmentKey {
    static let defaultValue: SupportLocale = SupportLocale.China.init()
}

extension EnvironmentValues {
    var playerLocale: SupportLocale {
        get { self[supportLocale.self] }
        set { self[supportLocale.self] = newValue }
    }
}

extension View {
    func playerLocale(_ supportLocale: SupportLocale) -> some View {
        environment(\.playerLocale, supportLocale)
    }
}
