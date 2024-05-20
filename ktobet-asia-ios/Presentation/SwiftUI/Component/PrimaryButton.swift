import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () async -> Void
  
    var body: some View {
        AsyncButton(
            label: {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .frame(height: 48)
                    .localized(weight: .regular, size: 16, color: nil)
            },
            action: {
                await action()
            })
            .buttonStyle(.fill)
            .lineLimit(1)
    }
}

struct DefaultButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PrimaryButton(title: "Default", action: { })
        }
    }
}
