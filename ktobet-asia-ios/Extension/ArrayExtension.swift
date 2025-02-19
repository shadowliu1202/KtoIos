import Foundation

extension Array {
  subscript(safe index: Int?) -> Element? {
    guard let index else { return nil }

    if index < 0 || index > count - 1 {
      return nil
    }
    else {
      return self[index]
    }
  }

  public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key: Element] {
    var dict = [Key: Element]()
    for element in self {
      dict[selectKey(element)] = element
    }
    return dict
  }

  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }

  func filterThenCast<T>() -> [T] {
    self.filter({ $0 is T }).map({ $0 as! T })
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

extension Optional where Wrapped: Collection {
  func isNullOrEmpty() -> Bool {
    guard let self else {
      return true
    }
    return self.isEmpty
  }
}

extension Array {
  func unique<T: Hashable>(map: (Element) -> (T)) -> [Element] {
    var set = Set<T>()
    var arrayOrdered = [Element]()
    for value in self {
      if !set.contains(map(value)) {
        set.insert(map(value))
        arrayOrdered.append(value)
      }
    }

    return arrayOrdered
  }
}

extension Array where Element: Equatable {
  func reorder(by preferredOrder: [Element]) -> [Element] {
    self.sorted { a, b -> Bool in
      guard let first = preferredOrder.firstIndex(of: a) else {
        return false
      }

      guard let second = preferredOrder.firstIndex(of: b) else {
        return true
      }

      return first < second
    }
  }
}
