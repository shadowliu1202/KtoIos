import SharedBu

class AccountPatternGeneratorFactory {
    static func create(_ supportLocale: SupportLocale) -> AccountPatternGenerator {
        switch supportLocale {
        case .China():
            return ChinaAccountPatternGenerator()
        case .Vietnam():
            return VietnamAccountPatternGenerator()
        default:
            return ChinaAccountPatternGenerator()
        }
    }
}

