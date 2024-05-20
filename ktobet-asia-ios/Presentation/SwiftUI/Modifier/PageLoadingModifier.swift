import sharedbu
import SwiftUI

struct PageLoadingModifier: ViewModifier {
    var isLoading = true

    func body(content: Content) -> some View {
        if !isLoading {
            content
        }
        else {
            SwiftUILoadingView()
        }
    }
}

extension View {
    func onPageLoading(_ isLoading: Bool) -> some View {
        self.modifier(PageLoadingModifier(isLoading: isLoading))
    }
}

struct PageLoadingModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, world!")
            .onPageLoading(true)
    }
}
