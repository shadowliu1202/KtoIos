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

struct EmptyParameter: Encodable { }

extension Encodable where Self == EmptyParameter {
    static var empty: EmptyParameter {
        EmptyParameter()
    }
}
