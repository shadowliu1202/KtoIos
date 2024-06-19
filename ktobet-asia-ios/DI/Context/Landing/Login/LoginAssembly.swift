//
//  LoginAssembly.swift
//  ktobet-asia-ios
//
//  Created by Neil Liu on 2024/6/5.
//

import Foundation
import Swinject

class LoginAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(OtpLoginViewModel.self, initializer: OtpLoginViewModel.init)
    }
}

