import SharedBu
@testable import ktobet_asia_ios_qat

class FakePlayerLocaleConfiguration: PlayerConfiguration, PlayerLocaleConfiguration {
    let stubSupportLocale: SupportLocale
    
    init(stubSupportLocale: SupportLocale) {
        self.stubSupportLocale = stubSupportLocale
    }
    
    func getCultureCode() -> String {
        return ""
    }
    
    func getSupportLocale() -> SupportLocale {
        return stubSupportLocale
    }
}
