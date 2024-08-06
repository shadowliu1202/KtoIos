import Foundation
import Swinject

class RegisterAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(LoginViewModel.self, initializer: LoginViewModel.init)
    }
}
