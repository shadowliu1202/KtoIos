import Foundation
import sharedbu
import SwiftUI

struct EnterLobby {
    typealias Action = (ProductType?) -> Void
    let action: Action
    func callAsFunction(productType: ProductType?) {
        action(productType)
    }
}

struct EnterLobbyKey: EnvironmentKey {
    static var defaultValue: EnterLobby = EnterLobby { _ in }
}

extension EnvironmentValues {
    var enterLobby: EnterLobby {
        get { self[EnterLobbyKey.self] }
        set { self[EnterLobbyKey.self] = newValue }
    }
}

extension View {
    func onEnterLobby(_ action: @escaping EnterLobby.Action) -> some View {
        environment(\.enterLobby, EnterLobby(action: action))
    }
}
