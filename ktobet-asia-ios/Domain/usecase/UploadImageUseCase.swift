import Foundation
import RxSwift
import sharedbu

protocol UploadImageUseCase {
  func uploadImage(imageData: Data) -> Single<UploadImage>
}

class UploadImageUseCaseImpl: UploadImageUseCase {
  var imageRepository: ImageRepository!

  init(_ imageRepository: ImageRepository) {
    self.imageRepository = imageRepository
  }

  func uploadImage(imageData: Data) -> Single<UploadImage> {
    self.imageRepository.uploadImage(imageData: imageData)
  }
}
