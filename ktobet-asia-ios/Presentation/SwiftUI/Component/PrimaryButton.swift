import SwiftUI

struct PrimaryButton: View {
    var key: LocalizedStringKey?
    var title: String?
    var action: () async -> Void

    @available(*, deprecated, message: "should use key: LocalizedStringKey initializer")
    init(title: String, action: @escaping () async -> Void) {
        key = nil
        self.title = title
        self.action = action
    }

    init(key: LocalizedStringKey, action: @escaping () async -> Void) {
        self.key = key
        title = nil
        self.action = action
    }

    var body: some View {
        AsyncButton(
            label: {
                (key != nil ? Text(key!) : Text(title!))
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .frame(height: 48)
                    .localized(weight: .regular, size: 16, color: nil)
            },
            action: {
                await action()
            }
        )
        .buttonStyle(.fill)
        .lineLimit(1)
    }
}

struct DefaultButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PrimaryButton(title: "Default", action: {})
            PrimaryButton(key: "common_yes", action: {})
        }
    }
}
