import UIKit

extension Dictionary where Value: Equatable {
  func keys(of element: Value) -> [Key] {
    filter { $0.1 == element }.map { $0.0 }
  }
}

extension Dictionary {
  func mapValues<T>(transform: (Value) -> T) -> [Key: T] {
    [Key: T](uniqueKeysWithValues: zip(self.keys, self.values.map(transform)))
  }
}
