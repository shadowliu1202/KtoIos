import SwiftUI

struct AsyncButton: View {
  var title: String
  var action: () async -> Void
  
  @State private var isPerformingTask = false
  
  var body: some View {
    Button(action: {
      Task {
        isPerformingTask = true
        await action()
        isPerformingTask = false
      }
    }, label: {
      Text(title)
    })
    .disabled(isPerformingTask)
  }
}

struct AsyncButton_Previews: PreviewProvider {
  static var previews: some View {
    AsyncButton(title: "test", action: { })
  }
}
