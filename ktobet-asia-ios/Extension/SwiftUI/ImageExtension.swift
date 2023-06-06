import SwiftUI

extension Image {
  public init?(uiImage: UIImage?) {
    guard let uiImage else {
      return nil
    }
    self = Image(uiImage: uiImage)
  }
}
