import Combine
import Foundation
import Photos
import SwiftUI

class ImagePickerViewModel: NSObject, ObservableObject {
  @Published private(set) var fetchResult: PHFetchResult<PHAsset> = PHFetchResult()
  @Published private(set) var albums: [PHAssetCollection] = []
  @Published private(set) var selectedAlbum: PHAssetCollection? = nil

  private let imageManager = PHCachingImageManager()
  
  private let requestContentMode: PHImageContentMode = .aspectFill
  
  private var cancellables = Set<AnyCancellable>()

  private(set) var imageSize: CGSize!
  private(set) var requestOptions: PHImageRequestOptions!
  
  let imagesPerPage = 30
  
  func setup(imageSize: CGSize) {
    setupRequestConfiguration(imageSize)
    checkAuthorizationStatus()
    observeChangeOfPhotoLibrary()
    setupAlbums()
    fetchImageOnSelectedAlbumChange()
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
  
  private func setupAlbums() {
    setSelectedAlbum(fetchAlbums().first)
  }
  
  func setSelectedAlbum(_ albums: PHAssetCollection?) {
    selectedAlbum = albums
  }
  
  private func fetchAlbums() -> [PHAssetCollection] {
    let albums = recentAddedAlbum() + screenShotsAlbum() + userCreatedAlbums()
    self.albums = albums
    
    return albums
  }
  
  private func recentAddedAlbum() -> [PHAssetCollection] {
    fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary)
  }
  
  private func screenShotsAlbum() -> [PHAssetCollection] {
    fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots)
  }
  
  private func userCreatedAlbums() -> [PHAssetCollection] {
    fetchAssetCollections(with: .album, subtype: .albumRegular)
  }
  
  private func fetchAssetCollections(with type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype) -> [PHAssetCollection] {
    let fetchResult = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: nil)
    return fetchResult.objects(at: IndexSet(0..<fetchResult.count))
  }
  
  private func fetchImageOnSelectedAlbumChange() {
    $selectedAlbum
      .compactMap { $0 }
      .sink(receiveValue: { [unowned self] in
        fetchImageAssets(in: $0)
      })
      .store(in: &cancellables)
  }
  
  private func fetchImageAssets(in album: PHAssetCollection) {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    
    fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
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
  
  func getSizeInMB(asset: PHAsset) -> Double {
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
  
  func getFileName(asset: PHAsset) -> String {
    asset.value(forKey: "filename") as? String ?? ""
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
