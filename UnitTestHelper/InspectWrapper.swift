import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

extension InspectWrapper {
    enum TestTag: String {
        case contentView
    }
}

struct InspectWrapper<Content: View>: View, Inspecting {
    let content: Content
  
    var inspection = Inspection<Self>()
  
    init(content: Content) {
        self.content = content
    }
  
    init(content: () -> Content) {
        self.content = content()
    }
  
    var body: some View {
        content
            .id(InspectWrapper.TestTag.contentView.rawValue)
            .onInspected(inspection, self)
    }
}
