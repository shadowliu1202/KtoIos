import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class DepositRecordDetailViewControllerTests: XCBaseTestCase {
  func buildUploadedImages() -> [RecordRemark.Uploader.Model] {
    (0...2).map { _ in
      .init(image: .init())
    }
  }

  func test_PaymentStatusIsFloating_SelectedThreePhotos_ClickUploadButtonWillPopAlert_KTO_TC_90() {
    let stubViewModel = mock(DepositRecordDetailViewModel.self)
      .initialize(
        depositService: mock(AbsDepositAppService.self),
        imageUseCase: mock(UploadImageUseCase.self),
        httpClient: getFakeHttpClient(),
        playerConfig: PlayerConfigurationImpl(nil))

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
        ["\(Configuration.uploadImageCountLimit)"]),
      confirm: any(),
      confirmText: any(),
      cancel: any(),
      cancelText: any(),
      tintColor: any()))
      .wasCalled(1)
  }
}
