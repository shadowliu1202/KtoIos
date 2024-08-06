import Foundation
import SwiftUI

struct HandleError {
    typealias Action = (Error) -> Void
    let action: Action
    func callAsFunction(error: Error) {
        action(error)
    }
}

struct HandleErrorKey: EnvironmentKey {
    static var defaultValue: HandleError = HandleError { _ in }
}

extension EnvironmentValues {
    var handleError: HandleError {
        get { self[HandleErrorKey.self] }
        set { self[HandleErrorKey.self] = newValue }
    }
}

extension View {
    func onHandleError(_ action: @escaping HandleError.Action) -> some View {
        environment(\.handleError, HandleError(action: action))
    }
}
