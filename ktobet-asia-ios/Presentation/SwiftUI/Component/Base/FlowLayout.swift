import SwiftUI

struct FlowLayout<T, Content: View>: View {
    @State private var totalHeight = CGFloat()
    @State private var totalWidth = CGFloat()

    private let items: [T]
    private let hSpacing: CGFloat
    private let vSpacing: CGFloat
    private let content: (T) -> Content

    init(
        items: [T],
        hSpacing: CGFloat,
        vSpacing: CGFloat,
        @ViewBuilder content: @escaping (T) -> Content)
    {
        self.items = items
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack(alignment: .topLeading) {
                var currentWidth = CGFloat()
                var currentHeight = CGFloat()
                var lastHeight = CGFloat()

                ForEach(items.indices, id: \.self) { index in
                    content(items[index])
                        .alignmentGuide(.leading) { viewDimensions in
                            if abs(currentWidth - viewDimensions.width) > geometryProxy.size.width {
                                currentWidth = 0
                                currentHeight -= (lastHeight + vSpacing)
                            }

                            lastHeight = viewDimensions.height
                            let result = currentWidth

                            if index == items.count - 1 {
                                currentWidth = 0
                            }
                            else {
                                currentWidth -= (viewDimensions.width + hSpacing)
                            }

                            return viewDimensions[.leading] + result
                        }
                        .alignmentGuide(.top) { viewDimensions in
                            let result = currentHeight

                            if index == items.count - 1 {
                                currentHeight = 0
                            }

                            return viewDimensions[.top] + result
                        }
                }
            }
            .background(HeightReaderView($totalHeight))
        }
        .frame(height: totalHeight)
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
  
    static func reduce(value _: inout CGFloat, nextValue _: () -> CGFloat) { }
}

private struct HeightReaderView: View {
    @Binding var height: CGFloat
  
    init(_ height: Binding<CGFloat>) {
        self._height = height
    }
  
    var body: some View {
        GeometryReader { geometryProxy in
            Color.clear
                .preference(
                    key: HeightPreferenceKey.self,
                    value: geometryProxy.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            self.height = height
        }
    }
}

struct FlowLayout_Previews: PreviewProvider {
    struct ColorItem: Identifiable {
        let id: UUID
        let color: Color
    }

    static let colors: [ColorItem] = (0..<30)
        .map { _ in
            ColorItem(
                id: UUID(),
                color: Color(
                    red: .random(in: 0...1),
                    green: .random(in: 0...1),
                    blue: .random(in: 0...1)))
        }

    static var previews: some View {
        Rectangle()
            .overlay(
                FlowLayout(
                    items: colors,
                    hSpacing: 10,
                    vSpacing: 10)
                { colorItem in
                    Rectangle()
                        .fill(colorItem.color)
                        .frame(width: 50, height: 50)
                })
    }
}
