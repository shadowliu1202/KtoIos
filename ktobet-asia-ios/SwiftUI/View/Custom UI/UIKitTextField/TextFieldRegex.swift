import Foundation

protocol TextFieldRegex {
    var pattern: String { get }
}

enum GeneralRegex: TextFieldRegex {
    case all
    case email
    case number
    case numberAndEnglish
    
    var pattern: String {
        switch self {
        case .all:
            return "^[\\s\\S]*$"
        case .email:
            return "^[0-9a-zA-Z_@\\-.\\/]*$"
        case .number:
            return "^[0-9]*$"
        case .numberAndEnglish:
            return "^[0-9a-zA-Z]*$"
        }
    }
}

enum CurrencyRegex: TextFieldRegex, Equatable {
    case noDecimal
    case withDecimal(Int)
    
    var pattern: String {
        switch self {
        case .noDecimal:
            return "^[0-9,]*$"
        case .withDecimal(let maxDigits):
            return "^[0-9,]*([.][0-9]{0,\(maxDigits)})?$"
        }
    }
    
    var maxDigits: Int? {
        switch self {
        case .noDecimal:
            return nil
        case .withDecimal(let maxDigits):
            return maxDigits
        }
    }
}
