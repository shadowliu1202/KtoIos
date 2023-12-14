import Foundation
import Photos
import SwiftUI

class ImagePickerViewModel: NSObject, ObservableObject {
  @Published private(set) var fetchResult: PHFetchResult<PHAsset> = PHFetchResult()
  
  private let imageManager = PHCachingImageManager()
  
  private let requestContentMode: PHImageContentMode = .aspectFill
  
  private(set) var imageSize: CGSize!
  private(set) var requestOptions: PHImageRequestOptions!
  
  let imagesPerPage = 30
  
  func setup(imageSize: CGSize) {
    checkAuthorizationStatus()
    observeChangeOfPhotoLibrary()
    setupImages(imageSize)
  }
  
  private func checkAuthorizationStatus() {
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .denied,
         .restricted:
      if let appSettings = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(appSettings)
      }
    default:
      break
    }
  }
  
  private func observeChangeOfPhotoLibrary() {
    PHPhotoLibrary.shared().register(self)
  }
  
  private func setupImages(_ imageSize: CGSize) {
    getFetchResult()
    setupRequestConfiguration(imageSize)
  }
  
  private func getFetchResult() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    
    fetchResult = PHAsset.fetchAssets(with: fetchOptions)
  }
  
  private func setupRequestConfiguration(_ imageSize: CGSize) {
    self.imageSize = imageSize
    
    requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat
  }
  
  func preLoadImages(for page: Int) {
    guard isPageExist(page) else { return }
    
    cacheImages(for: page)
  }
  
  private func isPageExist(_ page: Int) -> Bool {
    getStartIndex(at: page + 1) < fetchResult.count
  }
  
  private func cacheImages(for page: Int) {
    imageManager.startCachingImages(
      for: getAssets(for: page),
      targetSize: imageSize,
      contentMode: requestContentMode,
      options: requestOptions)
  }
  
  private func getAssets(for page: Int) -> [PHAsset] {
    let startIndex = getStartIndex(at: page)
    let endIndex = min(getStartIndex(at: page + 1), fetchResult.count)
    
    return fetchResult.objects(at: IndexSet(startIndex..<endIndex))
  }
  
  private func getStartIndex(at page: Int) -> Int {
    (page - 1) * imagesPerPage
  }
  
  func requestImage(for asset: PHAsset) async -> UIImage? {
    await imageManager.requestImage(
      for: asset,
      targetSize: imageSize,
      contentMode: requestContentMode,
      options: requestOptions)
  }
  
  func requestImageSizeInMB(asset: PHAsset) -> Double {
    let resources = PHAssetResource.assetResources(for: asset)

    guard
      let resource = resources.first,
      let fileSize = resource.value(forKey: "fileSize") as? Int64
    else {
      return 0
    }
    
    let fileSizeInMB = Double(fileSize) / 1_024 / 1_024
  
    return fileSizeInMB
  }
}

extension ImagePickerViewModel: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    DispatchQueue.main.async { [self] in
      guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
      fetchResult = changes.fetchResultAfterChanges
    }
  }
}

extension PHImageManager {
  func requestImage(
    for asset: PHAsset,
    targetSize: CGSize,
    contentMode: PHImageContentMode,
    options: PHImageRequestOptions?) async
    -> UIImage?
  {
    await withCheckedContinuation { continuation in
      self.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
        continuation.resume(returning: image)
      }
    }
  }
}
