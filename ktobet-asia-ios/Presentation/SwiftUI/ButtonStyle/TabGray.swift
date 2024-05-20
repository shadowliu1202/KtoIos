import SwiftUI

struct TabGray: ButtonStyle {
    private let onSelected: Bool

    init(onSelected: Bool) {
        self.onSelected = onSelected
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .localized(weight: .regular, size: 14, color: .greyScaleWhite)
            .frame(maxWidth: .infinity)
            .padding(4)
            .backgroundColor(
                onSelected ? .greyScaleIconDisable : .clear,
                alpha: onSelected ? 1 : 0)
            .animation(nil)
            .cornerRadius(8)
            .contentShape(Rectangle())
    }
}

struct TabGray_Previews: PreviewProvider {
    struct Preview: View {
        @State private var isSelected = true

        var body: some View {
            Button(
                action: {
                    isSelected.toggle()
                },
                label: {
                    Text("Press Me")
                })
                .buttonStyle(.tabGray(onSelected: isSelected))
                .frame(width: 150)
        }
    }

    static var previews: some View {
        Preview()
    }
}

extension ButtonStyle where Self == TabGray {
    static func tabGray(onSelected: Bool) -> TabGray {
        .init(onSelected: onSelected)
    }
}
