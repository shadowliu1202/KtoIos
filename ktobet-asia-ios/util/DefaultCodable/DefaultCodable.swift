import Foundation

protocol DefaultCodableValue {
  associatedtype Value: Codable
  static var defaultValue: Value { get }
}

@propertyWrapper
struct DefaultCodable<T: DefaultCodableValue> {
  var wrappedValue: T.Value
  
  init(wrappedValue: T.Value) {
    self.wrappedValue = wrappedValue
  }
  
  init(_ decodableValue: T) {
    self.wrappedValue = T.defaultValue
  }
}

extension DefaultCodable: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
  }
}

extension KeyedDecodingContainer {
  func decode<T>(
    _ type: DefaultCodable<T>.Type,
    forKey key: Key)
    throws -> DefaultCodable<T>
    where T: DefaultCodableValue
  {
    try decodeIfPresent(type, forKey: key) ?? DefaultCodable(wrappedValue: T.defaultValue)
  }
}
