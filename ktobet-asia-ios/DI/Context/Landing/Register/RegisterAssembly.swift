import Foundation
import Swinject

class RegisterAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(LoginViewModel.self, initializer: LoginViewModel.init)
    container.autoregister(SignupUserInfoViewModel.self, initializer: SignupUserInfoViewModel.init)
    container.autoregister(SignupPhoneViewModel.self, initializer: SignupPhoneViewModel.init)
    container.autoregister(SignupEmailViewModel.self, initializer: SignupEmailViewModel.init)
  }
}
