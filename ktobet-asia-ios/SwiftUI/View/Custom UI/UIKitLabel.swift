import SwiftUI

struct UIKitLabel: UIViewRepresentable {
    let configuration: (UILabel) -> Void

    func makeUIView(context: Context) -> UILabel {
        UILabel()
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        configuration(uiView)
    }
}
