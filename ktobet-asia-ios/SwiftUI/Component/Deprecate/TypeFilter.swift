import SwiftUI
import UIKit

@available(*, deprecated)
struct TypeFilter: View {
  let title: String

  var onPresentController: (() -> Void)?

  var body: some View {
    FunctionalButton(
      imageName: "icon.filter",
      content: {
        Text(title)
          .localized(
            weight: .medium,
            size: 14,
            color: .textPrimary)
          .lineLimit(1)
      },
      action: {
        onPresentController?()
      })
  }
}

struct TypeFilter_Previews: PreviewProvider {
  static var previews: some View {
    TypeFilter(title: "ABC")
  }
}
