import Foundation
import SwiftUI

struct ShowDialog {
    struct Info {
        let title: String?
        let message: String?
        var confirm: (() -> Void)? = nil
        var confirmText: String? = nil
        var cancel: (() -> Void)? = nil
        var cancelText: String? = nil
        var tintColor: UIColor? = nil
    }

    typealias Action = (Info) -> Void
    let action: Action
    func callAsFunction(info : Info) {
        action(info)
    }
}

struct ShowDialogKey: EnvironmentKey {
    static var defaultValue: ShowDialog = ShowDialog { _ in  }
}

extension EnvironmentValues {
    var showDialog: ShowDialog {
        get { self[ShowDialogKey.self] }
        set { self[ShowDialogKey.self] = newValue }
    }
}

extension View {
    func onShowDialog(_ action: @escaping ShowDialog.Action) -> some View {
        environment(\.showDialog, ShowDialog(action: action))
    }
}
