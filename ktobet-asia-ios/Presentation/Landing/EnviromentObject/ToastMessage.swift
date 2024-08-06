import Foundation
import SwiftUI

struct ToastMessage {
    typealias Action = (String, UIViewController.SnackBarStyle) -> Void
    let action: Action
    func callAsFunction(_ message: String, _ style: UIViewController.SnackBarStyle) {
        action(message, style)
    }
}

struct ToastMessageKey: EnvironmentKey {
    static var defaultValue: ToastMessage = ToastMessage { _, _ in }
}

extension EnvironmentValues {
    var toastMessage: ToastMessage {
        get { self[ToastMessageKey.self] }
        set { self[ToastMessageKey.self] = newValue }
    }
}

extension View {
    func onToastMessage(_ action: @escaping ToastMessage.Action) -> some View {
        environment(\.toastMessage, ToastMessage(action: action))
    }
}
