import Foundation
import sharedbu

class CommonOtpViewModel {
    private var configurationUseCase: ConfigurationUseCase!

    lazy var locale: SupportLocale = configurationUseCase.locale()

    init(_ configurationUseCase: ConfigurationUseCase) {
        self.configurationUseCase = configurationUseCase
    }

    var otpRetryCount: Int {
        get {
            configurationUseCase.getOtpRetryCount()
        }
        set {
            configurationUseCase.setOtpRetryCount(newValue)
        }
    }
}
