import SwiftUI
import UIKit

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
            color: .gray9B9B9B)
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
