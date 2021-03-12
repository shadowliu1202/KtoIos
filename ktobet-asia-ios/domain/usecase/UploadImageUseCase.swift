import Foundation
import RxSwift
import share_bu

protocol UploadImageUseCase {
    func uploadImage(imageData: Data) -> Single<UploadImageDetail>
}

class UploadImageUseCaseImpl: UploadImageUseCase {
    var imageRepository: ImageRepository!

    init(_ imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }

    func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
        return self.imageRepository.uploadImage(imageData: imageData)
    }
}
