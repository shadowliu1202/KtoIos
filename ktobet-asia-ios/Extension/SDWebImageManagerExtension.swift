import Foundation
import SDWebImage

extension SDWebImageManager {
  func loadImage(from url: String) async throws -> UIImage {
    try await
      withCheckedThrowingContinuation { continuation in
        var hasResumed = false
        
        self.loadImage(
          with: .init(string: url),
          options: [.refreshCached, .handleCookies],
          progress: nil)
        { image, _, error, _, _, _ in
          guard !hasResumed else { return }
          
          if let error {
            continuation.resume(throwing: error)
          }
          else if let image {
            continuation.resume(returning: image)
          }
          else {
            continuation.resume(throwing: KTOError.EmptyData)
          }
          
          hasResumed = true
        }
      }
  }
}
