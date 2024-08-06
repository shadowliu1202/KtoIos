import SwiftUI

struct BindingEnvironmentKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isCsProcessing: Binding<Bool> {
        get { self[BindingEnvironmentKey.self] }
        set { self[BindingEnvironmentKey.self] = newValue }
    }
}
