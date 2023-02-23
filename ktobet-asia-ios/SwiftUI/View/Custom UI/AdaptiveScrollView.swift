import SwiftUI

struct AdaptiveScrollView<Content: View>: View {
  @State private var isOverBound = false

  var content: Content

  let axis: Axis.Set
  let showsIndicators: Bool

  init(_ axis: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
    self.axis = axis
    self.showsIndicators = showsIndicators
    self.content = content()
  }

  var body: some View {
    GeometryReader { frameGeo in
      content
        .overlay(
          GeometryReader { contentGeo in
            Color.clear
              .onAppear {
                isOverBound = contentGeo.size.height > frameGeo.size.height
              }
              .onChange(of: contentGeo.size) { _ in
                isOverBound = contentGeo.size.height > frameGeo.size.height
              }
          })
        .wrappedInScrollView(when: isOverBound, axis, showsIndicators: showsIndicators)
    }
  }
}
