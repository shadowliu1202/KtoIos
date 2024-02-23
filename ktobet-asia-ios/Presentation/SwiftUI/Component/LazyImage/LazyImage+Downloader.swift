import RxSwift
import SDWebImage
import SwiftUI

extension LazyImage {
  enum Result: Equatable {
    case placeholder
    case success(UIImage)
    case failure(Error)

    var image: UIImage? {
      switch self {
      case .success(let image):
        return image
      
      case .failure,
           .placeholder:
        return nil
      }
    }

    var error: Error? {
      switch self {
      case .failure(let error):
        return error
      case .placeholder,
           .success:
        return nil
      }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.image == rhs.image
    }
  }

  class Downloader: ObservableObject {
    @Published var result: Result?

    private let manager: SDWebImageManager

    init(manager: SDWebImageManager = SDWebImageManager.shared) {
      self.manager = manager
    }

    @MainActor
    func image(from url: String, startWith _result: Result? = nil) async {
      if let _result {
        result = _result
      }

      do {
        let image = try await manager.loadImage(from: url)
        result = .success(image)
      }
      catch {
        result = .failure(error)
      }
    }
  }
}
