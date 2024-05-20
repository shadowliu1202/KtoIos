import Foundation
import SDWebImage
import sharedbu
import SwiftUI

class ChattingListViewModel: ObservableObject {
    @Published private(set) var downloadedImages: [String: UIImage] = [:]
  
    private let httpClient: HttpClient
  
    let downloadFail = UIImage()
  
    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
  
    func downloadImages(_ messages: [CustomerServiceDTO.ChatMessage]) {
        let imageMessages = messages.filter { isIncludeUploadedImage($0) }
    
        for message in imageMessages {
            downloadImageIfNeeded(message)
        }
    }
  
    private func isIncludeUploadedImage(_ message: CustomerServiceDTO.ChatMessage) -> Bool {
        if message.isProcessing == false {
            for content in message.contents {
                if content.type == .image {
                    return true
                }
            }
        }
    
        return false
    }
  
    private func downloadImageIfNeeded(_ message: CustomerServiceDTO.ChatMessage) {
        for content in message.contents {
            guard
                let image = content.image,
                !hasDownloadedImage(image.thumbnailPath())
            else { continue }
      
            downloadImage(image.thumbnailPath())
        }
    }

    private func hasDownloadedImage(_ key: String) -> Bool {
        if
            downloadedImages[key] == nil ||
            downloadedImages[key] == downloadFail
        {
            return false
        }
        else {
            return true
        }
    }
  
    func downloadImage(_ thumbnailPath: String) {
        downloadedImages[thumbnailPath] = nil
        let url = httpClient.host.absoluteString + thumbnailPath
    
        Task {
            let image = await (try? SDWebImageManager.shared.loadImage(from: url)) ?? downloadFail
            await MainActor.run(body: {
                guard !hasDownloadedImage(thumbnailPath) else { return }
                downloadedImages[thumbnailPath] = image
            })
        }
    }
}
