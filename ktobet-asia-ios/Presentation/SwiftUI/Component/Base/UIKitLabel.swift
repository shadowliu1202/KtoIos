import SwiftUI

struct UIKitLabel: UIViewRepresentable {
  let configuration: (UILabel) -> Void

  func makeUIView(context _: Context) -> UILabel {
    let label = UILabel()
    label.setContentHuggingPriority(.required, for: .horizontal)
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }

  func updateUIView(_ uiView: UILabel, context _: Context) {
    configuration(uiView)
  }
}
