import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class DepositRecordDetailViewControllerTests: XCTestCase {
  func buildUploadedImages() -> [DepositRecordDetailViewModel.UploadImage] {
    (0...2).map { _ in
      .init(
        image: .init(),
        detail: .init(
          uriString: "",
          portalImage: .Private(imageId: "", fileName: "", host: ""),
          fileName: ""))
    }
  }

  func test_PaymentStatusIsFloating_SelectedThreePhotos_ClickUploadButtonWillPopAlert_KTO_TC_90() {
    let stubViewModel = mock(DepositRecordDetailViewModel.self)
      .initialize(
        depositService: Injectable.resolveWrapper(ApplicationFactory.self).deposit(),
        imageUseCase: mock(UploadImageUseCase.self),
        httpClient: getFakeHttpClient())

    given(stubViewModel.errors()) ~> .never()
    given(stubViewModel.selectedImages) ~> self.buildUploadedImages()

    let stubAlert = mock(AlertProtocol.self)

    let sut = DepositRecordDetailViewController(
      transactionId: "",
      alert: stubAlert,
      viewModel: stubViewModel)

    sut.loadViewIfNeeded()

    sut.pushImagePicker()

    verify(stubAlert.show(
      any(),
      Localize.string(
        "common_photo_upload_limit_reached",
        ["\(DepositRecordDetailViewModel.selectedImageCountLimit)"]),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled(1)
  }
}
