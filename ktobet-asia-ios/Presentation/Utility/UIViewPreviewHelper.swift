import SwiftUI
import UIKit

struct UIViewPreviewHelper<View: UIView>: UIViewRepresentable {
  var view: View

  init(_ view: View) {
    self.view = view
  }

  func makeUIView(context _: Context) -> View {
    view
  }

  func updateUIView(_: View, context _: Context) { }
}
