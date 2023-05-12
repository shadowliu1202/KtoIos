import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalRecordDetailViewControllerTests: XCBaseTestCase {
  func buildUploadedImages() -> [RecordRemark.Uploader.Model] {
    (0...2).map { _ in
      .init(
        image: .init(),
        detail: .init(
          uriString: "",
          portalImage: .Private(imageId: "", fileName: "", host: ""),
          fileName: ""))
    }
  }

  func test_PaymentStatusIsFloating_SelectedThreePhotos_ClickUploadButtonWillPopAlert_KTO_TC_135() {
    let stubViewModel = mock(WithdrawalRecordDetailViewModel.self)
      .initialize(
        withdrawalService: Injectable.resolveWrapper(IWithdrawalAppService.self),
        imageUseCase: mock(UploadImageUseCase.self),
        httpClient: getFakeHttpClient(),
        playerConfig: PlayerConfigurationImpl())

    given(stubViewModel.errors()) ~> .never()
    given(stubViewModel.selectedImages) ~> self.buildUploadedImages()

    let stubAlert = mock(AlertProtocol.self)

    let sut = WithdrawalRecordDetailViewController(
      transactionId: "",
      alert: stubAlert,
      viewModel: stubViewModel)

    sut.loadViewIfNeeded()

    sut.pushImagePicker()

    verify(stubAlert.show(
      any(),
      Localize.string(
        "common_photo_upload_limit_reached",
        ["\(WithdrawalRecordDetailViewModel.selectedImageCountLimit)"]),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled(1)
  }
}
