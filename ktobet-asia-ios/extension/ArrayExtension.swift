import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        if index < 0 || index > count - 1{
            return nil
        } else {
            return self[index]
        }
    }
    
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key:Element] {
        var dict = [Key:Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }
}

extension Dictionary {
    func dictionaryToTuple<K, V>() -> [(K, V)] {
        var tuples: [(K, V)] = []
        for d in self {
            guard let key = d.key as? K, let value = d.value as? V else { return [] }
            tuples.append((key, value))
        }
        
        return tuples
    }
}


