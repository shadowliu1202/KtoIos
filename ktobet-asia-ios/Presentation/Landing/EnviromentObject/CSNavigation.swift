import Foundation
import SwiftUI

struct StartCustomerService {
    typealias Action = () -> Void
    let action: Action
    func callAsFunction() {
        action()
    }
}

struct StartCustomerServiceKey: EnvironmentKey {
    static var defaultValue: StartCustomerService = StartCustomerService {}
}

extension EnvironmentValues {
    var startCS: StartCustomerService {
        get { self[StartCustomerServiceKey.self] }
        set { self[StartCustomerServiceKey.self] = newValue }
    }
}

extension View {
    func onStartCS(_ action: @escaping StartCustomerService.Action) -> some View {
        environment(\.startCS, StartCustomerService(action: action))
    }
}
