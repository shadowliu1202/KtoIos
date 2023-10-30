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
      },
      action: {
        await action()
      })
      .lineLimit(1)
      .buttonStyle(.fill)
      .localized(weight: .regular, size: 16)
  }
}

struct DefaultButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      PrimaryButton(title: "Default", action: { })
    }
  }
}
