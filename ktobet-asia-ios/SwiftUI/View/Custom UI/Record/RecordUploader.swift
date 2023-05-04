import RxSwift
import UIKit

protocol RecordUploader: CollectErrorViewModel {
  var selectedImages: [RecordRemark.Uploader.Model] { get set }
  var imageUseCase: UploadImageUseCase { get }
  var disposeBag: DisposeBag { get }
}

extension RecordUploader {
  private func startUploadImages(_ uploads: [RecordRemark.Uploader.Model]) {
    let requests = uploads.compactMap { element -> Observable<RecordRemark.Uploader.Model>? in
      guard let data = element.image.jpegData(compressionQuality: 1.0) else { return nil }

      return imageUseCase
        .uploadImage(imageData: data)
        .map {
          RecordRemark.Uploader.Model(
            image: element.image,
            isUploading: false,
            detail: $0)
        }
        .do(onSuccess: { [weak self] in
          guard let index = self?.findSelectedImageIndex($0) else { return }
          self?.selectedImages[index] = $0
        }, onError: { [weak self] _ in
          self?.removeSelectedImage(element)
        })
        .asObservable()
    }

    Observable
      .combineLatest(requests)
      .subscribe(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  func prepareSelectedImages(_ images: [UIImage], shouldReplaceAll: Bool) {
    let selected = images.map { RecordRemark.Uploader.Model(image: $0) }

    if shouldReplaceAll {
      selectedImages = selected
    }
    else {
      selectedImages = selectedImages + selected
    }

    startUploadImages(selected)
  }

  func removeSelectedImage(_ selected: RecordRemark.Uploader.Model) {
    guard let index = findSelectedImageIndex(selected) else { return }
    selectedImages.remove(at: index)
  }

  func findSelectedImageIndex(_ selected: RecordRemark.Uploader.Model) -> Int? {
    guard let index = selectedImages.firstIndex(of: selected) else { return nil }
    return index
  }
}
