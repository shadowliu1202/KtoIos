import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class WithdrawalRecordDetailViewControllerTests: XCBaseTestCase {
    func buildUploadedImages() -> [RecordRemark.Uploader.Model] {
        (0...2).map { _ in
            .init(image: .init())
        }
    }

    func test_PaymentStatusIsFloating_SelectedThreePhotos_ClickUploadButtonWillPopAlert_KTO_TC_135() {
        let stubViewModel = mock(WithdrawalRecordDetailViewModel.self)
            .initialize(
                withdrawalService: Injectable.resolveWrapper(IWithdrawalAppService.self),
                imageUseCase: mock(UploadImageUseCase.self),
                httpClient: getFakeHttpClient(),
                playerConfig: PlayerConfigurationImpl(nil))

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
                ["\(Configuration.uploadImageCountLimit)"]),
            confirm: any(),
            confirmText: any(),
            cancel: any(),
            cancelText: any(),
            tintColor: any()))
            .wasCalled(1)
    }
}
