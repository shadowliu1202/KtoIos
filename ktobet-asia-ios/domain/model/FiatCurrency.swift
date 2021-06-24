import SharedBu
import UIKit

extension Currency {
    @objc var flagIcon: UIImage? {
        return nil
    }
    
}

class FiatCurrency: Currency {
    public var simpleName: String {
        get { return "" }
    }
    static func create(cultureCode: String) -> FiatCurrency {
        switch cultureCode {
        case "zh-cn": return CNY()
        default : fatalError("Not Support")
        }
    }
}

class CNY: FiatCurrency {
    override var simpleName: String {
        get { return "CNY" }
    }
    @objc override var flagIcon: UIImage? {
        return UIImage(named: "IconCryptoTypeCNY")
    }
    
}
