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
      default:
        return nil
      }
    }

    var error: Error? {
      switch self {
      case .failure(let error):
        return error
      default:
        return nil
      }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.image == rhs.image
    }
  }

  class Downloader: ObservableObject {
    @Published var result: Result?

    private let downloader: SDWebImageDownloader

    var headers: [String: String]? {
      didSet {
        headers?.forEach {
          downloader.setValue($0.value, forHTTPHeaderField: $0.key)
        }
      }
    }

    init(downloader: SDWebImageDownloader = .shared) {
      self.downloader = downloader
    }

    @MainActor
    func image(from url: String, startWith _result: Result? = nil) async {
      if let _result {
        result = _result
      }
      
      do {
        let image = try await downloader.image(from: url)
        result = .success(image)
      }
      catch {
        result = .failure(error)
      }
    }
  }
}

// MARK: - SDWebImageDownloader

extension SDWebImageDownloader {
  fileprivate func image(from url: String) async throws -> UIImage {
    try await
      withCheckedThrowingContinuation { continuation in
        self.downloadImage(with: .init(string: url)) { image, _, error, _ in
          if let error {
            continuation.resume(throwing: error)
          }
          else if let image {
            continuation.resume(returning: image)
          }
          else {
            continuation.resume(throwing: KTOError.EmptyData)
          }
        }
      }
  }
}
