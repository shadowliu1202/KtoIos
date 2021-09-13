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
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func filterThenCast<T>() -> Array<T> {
        return self.filter({ $0 is T }).map({ $0 as! T})
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
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


