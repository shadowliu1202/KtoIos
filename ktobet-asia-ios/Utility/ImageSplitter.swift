import Foundation
import Photos
import RxSwift
import sharedbu

class ImageSplitter {
    static let chunkSize = 512 * 1024
  
    static func processImage(by localIdentifier: String) -> ([Data], Int)? {
        guard let imageData = fetchImageData(by: localIdentifier) else { return nil }
    
        return (createChunks(imageData), imageData.count)
    }
  
    private static func fetchImageData(by localIdentifier: String) -> Data? {
        guard
            let asset = PHAsset
                .fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                .firstObject
        else {
            return nil
        }
    
        let image = asset.convertAssetToImage()
    
        return image.jpegData(compressionQuality: 1)!
    }
  
    private static func createChunks(_ imageData: Data) -> [Data] {
        var chunks: [Data] = []
    
        let dataLen = imageData.count
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
    
        for chunkCounter in 0..<totalChunks {
            var chunk: Data
            let chunkBase = chunkCounter * chunkSize
            var diff = chunkSize
            if chunkCounter == totalChunks - 1 {
                diff = dataLen - chunkBase
            }

            chunk = imageData.subdata(in: chunkBase..<(chunkBase + diff))
            chunks.append(chunk)
        }
    
        return chunks
    }
}
