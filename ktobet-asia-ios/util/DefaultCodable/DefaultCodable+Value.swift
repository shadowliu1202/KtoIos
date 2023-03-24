import Foundation

extension Bool {
  struct Custom: DefaultCodableValue {
    static var defaultValue = false
    
    init (_ customValue: Bool) {
      Self.defaultValue = customValue
    }
  }
  
  static let `false` = Custom(false)
}

extension String {
  struct Custom: DefaultCodableValue {
    static var defaultValue = ""
    
    init (_ customValue: String) {
      Self.defaultValue = customValue
    }
  }
  
  static let maximumDate = Custom("9999-12-31T23:59:59.999+00:00")
  static let minimumDate = Custom("0001-01-01T00:00:00.000+00:00")
}

extension Double {
  struct Custom: DefaultCodableValue {
    static var defaultValue: Double = 0
    
    init (_ customValue: Double) {
      Self.defaultValue = customValue
    }
  }
  
  static let zero = Custom(0)
}
