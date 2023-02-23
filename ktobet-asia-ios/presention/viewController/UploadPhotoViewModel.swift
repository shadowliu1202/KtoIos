import Foundation
import RxSwift
import SharedBu

class UploadPhotoViewModel {
  private var imageUseCase: UploadImageUseCase!

  init(imageUseCase: UploadImageUseCase) {
    self.imageUseCase = imageUseCase
  }

  func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
    imageUseCase.uploadImage(imageData: imageData)
  }
}
