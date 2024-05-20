// Reference: https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/
import Foundation

let suiteName = "Persistent"

@propertyWrapper
struct Persistent<T: PropertyListValue> {
    let key: Key

    private lazy var defaults = UserDefaults(suiteName: suiteName)

    init(key: Key) {
        self.key = key
    }

    var wrappedValue: T? {
        mutating get { defaults?.value(forKey: key.rawValue) as? T }
        set { defaults?.set(newValue, forKey: key.rawValue) }
    }

    var projectedValue: Persistent<T> { self }

    func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        UserDefaultsObservation(suiteName: suiteName, key: key) { old, new in
            change(old as? T, new as? T)
        }
    }

    static func clear() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}

@propertyWrapper
struct PersistentObject<T: Codable> {
    let key: Key

    private lazy var defaults = UserDefaults(suiteName: suiteName)

    init(key: Key) {
        self.key = key
    }

    var wrappedValue: T? {
        mutating get { try! getObject(forKey: key.rawValue, castTo: T.self) }
        set { try! setObject(newValue, forKey: key.rawValue) }
    }

    var projectedValue: PersistentObject<T> { self }

    func observe(change: @escaping (T?, T?) -> Void) -> NSObject {
        UserDefaultsObservation(suiteName: suiteName, key: key) { old, new in
            change(old as? T, new as? T)
        }
    }

    static func clear() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private mutating func setObject(_ object: T?, forKey: String) throws {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            defaults?.set(data, forKey: forKey)
        }
        catch {
            throw ObjectSavableError.unableToEncode
        }
    }

    private mutating func getObject(forKey: String, castTo type: T.Type) throws -> T where T: Decodable {
        guard let data = defaults?.data(forKey: forKey) else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        }
        catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}

struct Key: RawRepresentable {
    let rawValue: String
}

extension Key: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        rawValue = stringLiteral
    }
}

// The marker protocol
protocol PropertyListValue { }

extension Data: PropertyListValue { }
extension String: PropertyListValue { }
extension Date: PropertyListValue { }
extension Bool: PropertyListValue { }
extension Int: PropertyListValue { }
extension Int32: PropertyListValue { }
extension Double: PropertyListValue { }
extension Float: PropertyListValue { }

// Every element must be a property-list type
extension Array: PropertyListValue where Element: PropertyListValue { }
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue { }

class UserDefaultsObservation: NSObject {
    let key: Key
    private var onChange: (Any, Any) -> Void
    let suiteName: String?
    private lazy var defaults = UserDefaults(suiteName: suiteName)

    init(suiteName: String? = nil, key: Key, onChange: @escaping (Any, Any) -> Void) {
        self.onChange = onChange
        self.key = key
        self.suiteName = suiteName
        super.init()
        defaults?.addObserver(self, forKeyPath: key.rawValue, options: [.old, .new], context: nil)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context _: UnsafeMutableRawPointer?)
    {
        guard let change, object != nil, keyPath == key.rawValue else { return }
        onChange(change[.oldKey] as Any, change[.newKey] as Any)
    }

    deinit {
        defaults?.removeObserver(self, forKeyPath: key.rawValue, context: nil)
    }
}
