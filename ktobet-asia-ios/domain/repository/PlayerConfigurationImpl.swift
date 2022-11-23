import SharedBu

class PlayerConfigurationImpl: PlayerConfiguration,
                               LocalStorable {
    
    private lazy var _supportLocale = getSupportLocale()
    
    override var supportLocale: SupportLocale { _supportLocale }
    
    override init() { }
    
    init(_supportLocale: SupportLocale) {
        super.init()
        self._supportLocale = _supportLocale
    }
    
    func getSupportLocale() -> SupportLocale {
        let code = get(key: .cultureCode) ?? ""
        return SupportLocale.Companion().create(language: code)
    }
}
