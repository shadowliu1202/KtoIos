import sharedbu
import SwiftUI

struct WithdrawalRecordDetailView<ViewModel>: View
  where ViewModel: WithdrawalRecordDetailViewModelProtocol & ObservableObject
{
  @StateObject var viewModel: ViewModel

  let transactionId: String

  var onUploadImage: (() -> Void)?
  var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

  var inspection = Inspection<Self>()

  var shouldShowUploader: Bool {
    viewModel.log?.status == .floating
  }

  var body: some View {
    RecordDetail(
      title: Localize.string("withdrawal_detail_title"),
      rowTypes: [
        .amount(viewModel.log?.amount.formatString()),
        .status(
          date: viewModel.log?.status == .pending ?
            nil : viewModel.log?.createdDate.toDateTimeString(),
          content: viewModel.log?.status.toString()),
        .applyDate(viewModel.log?.createdDate.toDateTimeString()),
        .withdrawalId(viewModel.log?.displayId),
        .remark(.init(
          previous: viewModel.remarks,
          uploader: $viewModel.selectedImages,
          onClickImage: onClickImage,
          onUpload: onUploadImage,
          imagesOnSend: viewModel.confirmUploadedImages,
          isAllowSendImages: viewModel.isAllowConfirm,
          isDeposit: false))
      ],
      shouldShowUploader: shouldShowUploader,
      shouldShowButtons: viewModel.isCancelable,
      isLoading: viewModel.log == nil,
      buttons: {
        Button(
          action: {
            viewModel.cancelWithdrawal()
          },
          label: {
            Text(Localize.string("withdrawal_cancel"))
          })
          .visibility(viewModel.isCancelable ? .visible : .gone)
          .buttonStyle(ConfirmRed(size: 16))
      })
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

struct WithdrawalRecordDetailView_Previews: PreviewProvider {
  class ViewModel:
    WithdrawalRecordDetailViewModelProtocol,
    ObservableObject
  {
    var log: WithdrawalDto.Log?
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
        uploadedURLs: (0...2).map { _ in
          (
            "",
            "https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/store-card-14-16-mac-nav-202301?wid=200&hei=130&fmt=png-alpha&.v=1670959891635")
        })
    ]
    var selectedImages: [RecordRemark.Uploader.Model] = []
    var httpHeaders: [String: String] = [:]
    var isAllowConfirm = true
    var isCancelable = false
    var supportLocale: SupportLocale = .China()

    func prepareForAppear(transactionId _: String) { }
    func observeFiatLog() { }
    func confirmUploadedImages() { }
    func cancelWithdrawal() { }

    init(status: WithdrawalDto.LogStatus) {
      self.log = .init(
        displayId: "TestId",
        amount: 100.toAccountCurrency(),
        createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
        status: status,
        type: .fiat,
        isPendingHold: false)

      switch status {
      case .floating:
        isCancelable = true
        selectedImages = (0...2).map { _ in
          .init(
            image: .init(named: "AppIconNotProd")!,
            detail: .init(uriString: "", portalImage: .Public(imageId: "", fileName: "", host: ""), fileName: ""))
        }

      default: return
      }
    }
  }

  static var previews: some View {
    WithdrawalRecordDetailView(
      viewModel: ViewModel(status: .floating),
      transactionId: "")

    WithdrawalRecordDetailView(
      viewModel: ViewModel(status: .pending),
      transactionId: "")
  }
}
