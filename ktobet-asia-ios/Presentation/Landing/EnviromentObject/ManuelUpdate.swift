import Foundation
import SwiftUI

struct StartManuelUpdate {
    typealias Action = () -> Void
    let action: Action
    func callAsFunction() {
        action()
    }
}

struct StartManuelUpdateKey: EnvironmentKey {
    static var defaultValue = StartManuelUpdate {}
}

extension EnvironmentValues {
    var startManuelUpdate: StartManuelUpdate {
        get { self[StartManuelUpdateKey.self] }
        set { self[StartManuelUpdateKey.self] = newValue }
    }
}

extension View {
    func onStartManuelUpdate(_ action: @escaping StartManuelUpdate.Action) -> some View {
        environment(\.startManuelUpdate, StartManuelUpdate(action: action))
    }
}
