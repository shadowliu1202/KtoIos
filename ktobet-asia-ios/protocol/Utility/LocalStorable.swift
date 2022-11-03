import Foundation

enum ObjectSavableError: String, LocalizedError {
    case unableToEncode = "Unable to encode object into data"
    case noValue = "No data object found for the given key"
    case unableToDecode = "Unable to decode object into given type"
    
    var errorDescription: String? {
        rawValue
    }
}

protocol LocalStorable { }

extension LocalStorable {
    
    typealias Key = UserDefaults.Key
    
    func set<T>(value: T?, key: Key) {
        if value == nil { UserDefaults.standard.removeObject(forKey: key.rawValue) }
        else { UserDefaults.standard.setValue(value, forKey: key.rawValue) }
    }

    func get<T>(key: Key) -> T? {
        guard let value = UserDefaults.standard.object(forKey: key.rawValue) as? T
        else {
            return nil
        }
        return value
    }
    
    /// Save custom objects into UserDefaults
    func setObject<Object>(_ object: Object, for key: Key) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key.rawValue)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    /// Get custom objects into UserDefaults
    func getObject<Object>(key: Key, to type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else { throw ObjectSavableError.noValue }
        
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}
