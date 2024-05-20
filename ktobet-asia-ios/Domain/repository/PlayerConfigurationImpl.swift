import sharedbu

class PlayerConfigurationImpl: PlayerConfiguration {
    private let _supportLocale: SupportLocale

    override var supportLocale: SupportLocale { _supportLocale }

    init(_ cultureCode: String?) {
        if let cultureCode {
            _supportLocale = SupportLocale.companion.create(language: cultureCode)
        }
        else {
            _supportLocale = PlayerConfiguration.defaultLocale
        }
    
        super.init()
    }
}
