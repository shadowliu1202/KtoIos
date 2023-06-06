import Foundation

extension Encodable {
  subscript(key: String) -> Any? {
    dictionary[key]
  }

  var dictionary: [String: Any] {
    let encoder = JSONEncoder()
    return (try? JSONSerialization.jsonObject(with: encoder.encode(self))) as? [String: Any] ?? [:]
  }
}
