import Foundation

extension RangeReplaceableCollection where Element: Equatable {
  @discardableResult
  mutating func appendIfNotContains(_ element: Element) -> (appended: Bool, memberAfterAppend: Element) {
    if let index = firstIndex(of: element) {
      return (false, self[index])
    }
    else {
      append(element)
      return (true, element)
    }
  }
}
