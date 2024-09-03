import sharedbu
import SwiftUI

struct DepositRecordDetailView<ViewModel>: View
    where ViewModel: DepositRecordDetailViewModelProtocol & ObservableObject
{
    @StateObject var viewModel: ViewModel

    let transactionId: String

    var onUploadImage: (() -> Void)?
    var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
        RecordDetail(
            title: Localize.string("deposit_detail_title"),
            rowTypes: [
                .amount(viewModel.log?.amount.formatString()),
                .status(
                    date: viewModel.log?.status == .pending ?
                        nil : viewModel.log?.updateDate.toDateTimeString(),
                    content: viewModel.log?.status.toLogString()),
                .applyDate(viewModel.log?.createdDate.toDateTimeString()),
                .depositId(viewModel.log?.displayId),
                .remark(.init(
                    previous: viewModel.remarks,
                    uploader: $viewModel.selectedImages,
                    onClickImage: onClickImage,
                    onUpload: onUploadImage,
                    imagesOnSend: viewModel.confirmUploadedImages,
                    isAllowSendImages: viewModel.isAllowConfirm,
                    isDeposit: true))
            ],
            shouldShowUploader: viewModel.log?.status == .floating,
            isLoading: viewModel.log == nil)
            .environment(\.playerLocale, viewModel.supportLocale)
            .environmentObject(viewModel)
            .onViewDidLoad {
                viewModel.prepareForAppear(transactionId: transactionId)
                viewModel.observeFiatLog()
            }
            .onInspected(inspection, self)
    }
}

// MARK: - Preview

struct DepositRecordDetailView_Previews: PreviewProvider {
    class ViewModel:
        DepositRecordDetailViewModelProtocol,
        ObservableObject
    {
        var log: PaymentLogDTO.Log?
        var remarks: [RecordRemark.Previous.Model] = [
            .init(
                updateHistory: .init(
                    createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                    imageIds: [],
                    remarkLevel1: "remarkLevel1",
                    remarkLevel2: "remarkLevel2",
                    remarkLevel3: "remarkLevel3"),
                host: ""),
            .init(
                updateHistory: .init(
                    createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                    imageIds: [],
                    remarkLevel1: "",
                    remarkLevel2: "",
                    remarkLevel3: "remarkLevel3-1"),
                host: "",
                uploadedURLs: [
                    (
                        "",
                        "https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/store-card-14-16-mac-nav-202301?wid=200&hei=130&fmt=png-alpha&.v=1670959891635"),
                    (
                        "",
                        "https://i.epochtimes.com/assets/uploads/2018/01/nature-2058243_1920-600x338.jpg"),
                    (
                        "",
                        "https://obs.line-scdn.net/0hJM6rJ9BPFWILCwIZno9qNS9dFg04ZwZhbz1EcFxuLTwmPFI0ZWVTUSxcTAAjPgZgN2UOASwOQ1VjOgYwPj4NViw/w644")
                ])
        ]
        var selectedImages: [RecordRemark.Uploader.Model]
        var httpHeaders: [String: String] = [:]
        var isAllowConfirm = true
        var supportLocale: SupportLocale = .China()

        func prepareForAppear(transactionId _: String) { }
        func observeFiatLog() { }
        func confirmUploadedImages() { }

        init(status: PaymentStatus, uploadingImages: [RecordRemark.Uploader.Model]) {
            self.log = .init(
                displayId: "TestId",
                currencyType: .fiat,
                status: status,
                amount: 100.toAccountCurrency(),
                createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
            selectedImages = uploadingImages
        }
    }

    static var previews: some View {
        DepositRecordDetailView(
            viewModel: ViewModel(status: .floating, uploadingImages: [
                .init(image: .init(named: "全站維護")!),
                .init(image: .init(named: "group1-4")!),
                .init(image: .init(named: "AppIconDev")!)
            ]),
            transactionId: "")
            .previewDisplayName("Status: Floating")

        DepositRecordDetailView(
            viewModel: ViewModel(status: .pending, uploadingImages: []),
            transactionId: "")
            .previewDisplayName("Status: Pending")
    }
}
