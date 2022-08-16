import SwiftUI

struct PageContainer<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            LimitSpacer(26)
            content
            LimitSpacer(96)
        }
    }
}

struct PageContainer_Previews: PreviewProvider {
    static var previews: some View {
        PageContainer {
            Rectangle().foregroundColor(.black)
        }
    }
}
