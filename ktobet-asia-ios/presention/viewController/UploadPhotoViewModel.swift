import Foundation
import RxSwift
import share_bu

class UploadPhotoViewModel {
    private var imageUseCase : UploadImageUseCase!

    init(imageUseCase: UploadImageUseCase) {
        self.imageUseCase = imageUseCase
    }

    func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
        return imageUseCase.uploadImage(imageData: imageData)
    }
}
