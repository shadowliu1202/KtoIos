import Combine
import SwiftUI

internal final class Inspection<V> {
  let notice = PassthroughSubject<UInt, Never>()
  var callbacks = [UInt: (V) -> Void]()

  func visit(_ view: V, _ line: UInt) {
    if let callback = callbacks.removeValue(forKey: line) {
      callback(view)
    }
  }
}

extension View {
  func onInspected<Content: View>
  (_ inspection: Inspection<Content>, _ target: Content)
    -> some View
  {
    onReceive(inspection.notice) {
      inspection.visit(target, $0)
    }
  }
}
