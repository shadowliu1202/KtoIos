import SwiftUI

extension AsyncButton {
  enum Identifier: String {
    case asyncButton
    case asyncButtonText
  }
}

@MainActor
struct AsyncButton<Label: View>: View {
  @State private var isPerformingTask = false
  
  @ViewBuilder var label: () -> Label
  
  var action: () async -> Void
  
  var body: some View {
    Button(action: {
      Task {
        isPerformingTask = true
        await action()
        isPerformingTask = false
      }
    }, label: {
      label()
        .id(AsyncButton.Identifier.asyncButtonText.rawValue)
    })
    .disabled(isPerformingTask)
    .id(AsyncButton.Identifier.asyncButton.rawValue)
  }
}

struct AsyncButton_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      AsyncButton(
        label: {
          Text(Localize.string("common_done"))
            .frame(maxWidth: .infinity)
            .padding(10)
        },
        action: { })
        .buttonStyle(.fill)
    }
  }
}
