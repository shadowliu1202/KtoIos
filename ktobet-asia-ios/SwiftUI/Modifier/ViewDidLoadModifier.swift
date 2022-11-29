import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
    @State private var viewDidLoad = false
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !viewDidLoad {
                    viewDidLoad = true
                    action?()
                }
            }
    }
}

extension View {
    
    func onViewDidLoad(_ perform: @escaping (() -> Void)) -> some View {
        self.modifier(ViewDidLoadModifier(action: perform))
    }
}
