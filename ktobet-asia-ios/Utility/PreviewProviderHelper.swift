import Foundation
import sharedbu

@available(*, deprecated, message: "Only use in PreviewProvider")
class FakePlayerConfiguration: PlayerConfiguration {
    private let _supportLocale: SupportLocale
  
    override var supportLocale: SupportLocale { _supportLocale }
  
    init(_ supportLocale: SupportLocale) {
        self._supportLocale = supportLocale
    
        super.init()
    }
}
