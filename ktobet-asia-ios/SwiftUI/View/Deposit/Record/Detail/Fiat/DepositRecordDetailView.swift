import SharedBu
import SwiftUI

struct DepositRecordDetailView<ViewModel>: View
  where ViewModel: DepositRecordDetailViewModelProtocol & ObservableObject
{
  @StateObject var viewModel: ViewModel

  let playerConfig: PlayerConfiguration
  let transactionId: String

  var onUploadImage: (() -> Void)?
  var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        Text(Localize.string("deposit_detail_title"))
          .localized(
            weight: .semibold,
            size: 24,
            color: .whitePure)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 30)

        LimitSpacer(30)

        Fields(
          rowTypes: [
            .amount,
            .status,
            .applyDate,
            .depositId,
            .remark
          ],
          onUploadImage: onUploadImage,
          onClickImage: onClickImage)
      }
    }
    .onPageLoading(viewModel.remarks.isEmpty || viewModel.log == nil)
    .pageBackgroundColor(.gray131313)
    .environment(\.playerLocale, playerConfig.supportLocale)
    .environmentObject(viewModel)
    .onViewDidLoad {
      viewModel.prepareForAppear(transactionId: transactionId)
      viewModel.observeFiatLog()
    }
  }
}

// MARK: - Components

extension DepositRecordDetailView {
  struct Fields: View {
    @EnvironmentObject var viewModel: ViewModel

    let rowTypes: [DepositRecordDetailView.Row.`Type`]

    var onUploadImage: (() -> Void)?
    var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

    var body: some View {
      Separator(color: .gray3C3E40)

      VStack {
        ForEach(rowTypes.indices, id: \.self) {
          LimitSpacer(8)

          DepositRecordDetailView.Row(
            type: rowTypes[$0],
            shouldShowBottomLine: $0 != rowTypes.count - 1,
            onUploadImage: onUploadImage,
            onClickImage: onClickImage)
        }
      }
      .padding(.horizontal, 30)

      Separator(color: .gray3C3E40)
        .visibility(viewModel.log?.status == .floating ? .gone : .visible)
    }
  }

  struct Row: View {
    enum `Type`: CaseIterable {
      case amount
      case status
      case applyDate
      case depositId
      case remark
    }

    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.playerLocale) var locale: SupportLocale

    let type: `Type`
    let shouldShowBottomLine: Bool

    var onUploadImage: (() -> Void)?
    var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

    var log: PaymentLogDTO.Log? { viewModel.log }

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(spacing: 8) {
        switch type {
        case .amount:
          buildDefault(
            titleTag: "common_transactionamount",
            content: viewModel.log?.amount.formatString())

        case .status:
          buildDefault(
            titleTag: "common_status",
            date: viewModel.log?.status == .pending ?
              nil : viewModel.log?.updateDate.toDateTimeString(),
            content: viewModel.log?.status.toLogString())

        case .applyDate:
          buildDefault(
            titleTag: "common_applytime",
            content: viewModel.log?.createdDate.toDateTimeString())

        case .depositId:
          buildDefault(
            titleTag: "deposit_ticketnumber",
            content: viewModel.log?.displayId)

        case .remark:
          buildRemark()
        }

        Separator(color: .gray3C3E40)
          .visibility(shouldShowBottomLine ? .visible : .gone)
      }
      .onInspected(inspection, self)
    }

    func buildDefault(
      titleTag: String? = nil,
      date: String? = nil,
      content: String?)
      -> some View
    {
      VStack(spacing: 2) {
        Text(Localize.string(titleTag ?? ""))
          .localized(
            weight: .regular,
            size: 12,
            color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .leading)
          .visibility(titleTag == nil ? .gone : .visible)

        Text(date ?? "")
          .localized(
            weight: .regular,
            size: 12,
            color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .leading)
          .visibility(date == nil ? .gone : .visible)

        Text(content ?? "")
          .localized(
            weight: .regular,
            size: 16,
            color: .whitePure)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }

    func buildRemark() -> some View {
      VStack(spacing: 2) {
        Text(Localize.string("common_remark"))
          .localized(
            weight: .regular,
            size: 12,
            color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 18) {
          ForEach(viewModel.remarks.indices, id: \.self) {
            let remark = viewModel.remarks[$0]

            VStack(spacing: 12) {
              buildDefault(
                date: remark.date,
                content: remark.content)

              HStack(spacing: 12) {
                ForEach(0...2, id: \.self) { index in
                  let uploaded = remark.uploadedURLs[safe: index]

                  if let uploaded {
                    Rectangle()
                      .fill(Color.clear)
                      .overlay(
                        LazyImage(
                          headers: viewModel.downloadHeaders,
                          url: uploaded.thumbnail)
                        { image in
                          Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .onTapGesture {
                              onClickImage?(uploaded.url, image)
                            }
                        })
                      .aspectRatio(1, contentMode: .fill)
                      .cornerRadius(4)
                  }
                  else { Rectangle().fill(Color.clear) }
                }
              }
              .visibility(remark.uploadedURLs.isEmpty ? .gone : .visible)
            }
          }
        }

        if viewModel.log?.status == .floating {
          LimitSpacer(22)
          buildSelectImage()
        }
        else {
          LimitSpacer(54)
        }
      }
    }

    func buildSelectImage() -> some View {
      VStack(spacing: 40) {
        VStack(spacing: 12) {
          Text(Localize.string("common_upload_file"))
            .localized(
              weight: .regular,
              size: 16,
              color: .whitePure)
            .frame(maxWidth: .infinity, alignment: .leading)

          ForEach(viewModel.selectedImages.indices, id: \.self) { index in
            let selected = viewModel.selectedImages[index]

            ZStack(alignment: .topLeading) {
              Image(uiImage: selected.image)
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
                .allowsHitTesting(false)
                .overlay(
                  SwiftUIGradientArcView(
                    isVisible: selected.isUploading)
                    .frame(width: 30, height: 30))

              Button(
                action: {
                  viewModel.removeSelectedImage(selected)
                },
                label: {
                  Text(Localize.string("common_remove"))
                    .localized(
                      weight: .medium,
                      size: 14,
                      color: .whitePure)
                    .frame(width: 52, height: 32)
                })
                .backgroundColor(.blackPure, alpha: 0.5)
                .cornerRadius(10)
                .alignmentGuide(.leading, computeValue: { $0[.leading] - 12 })
                .alignmentGuide(.top, computeValue: { $0[.top] - 12 })
            }
          }

          Button(
            action: {
              onUploadImage?()
            },
            label: {
              HStack(spacing: 10) {
                Image("iconPhoto24")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 20, height: 20)

                Text(Localize.string("common_click_to_upload"))
                  .localized(
                    weight: .medium,
                    size: 14,
                    color: .gray9B9B9B)
                  .frame(maxWidth: .infinity, alignment: .leading)

                Image("iconChevronRight16")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 16, height: 16)
              }
              .padding(.horizontal, 17)
            })
            .frame(maxWidth: .infinity, minHeight: 48)
            .backgroundColor(.gray333333)
            .cornerRadius(4)

          Text(Localize.string("common_photo_upload_limit"))
            .localized(
              weight: .medium,
              size: 14,
              color: .gray9B9B9B)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Button(
          action: {
            viewModel.confirmUploadedImages()
          },
          label: {
            Text(Localize.string("common_submit"))
          })
          .buttonStyle(ConfirmRed(size: 16))
          .disabled(!viewModel.isAllowConfirm)
      }
    }
  }
}

// MARK: - Preview

struct DepositRecordDetailView_Previews: PreviewProvider {
  class ViewModel:
    DepositRecordDetailViewModelProtocol,
    ObservableObject
  {
    var log: PaymentLogDTO.Log?

    var remarks: [DepositRecordDetailViewModel.Remark] = [
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

    var selectedImages: [DepositRecordDetailViewModel.UploadImage] = []

    var downloadHeaders: [String: String] = [:]
    var isAllowConfirm = true

    func prepareForAppear(transactionId _: String) { }
    func prepareSelectedImages(_: [UIImage], shouldReplaceAll _: Bool) { }
    func removeSelectedImage(_: DepositRecordDetailViewModel.UploadImage) { }
    func confirmUploadedImages() { }
    func observeFiatLog() { }

    init(status: PaymentStatus) {
      self.log = .init(
        displayId: "TestId",
        currencyType: .fiat,
        status: status,
        amount: 100.toAccountCurrency(),
        createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
        updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))

      switch status {
      case .floating:
        selectedImages = (0...2).map { _ in
          .init(
            image: .init(named: "AppIconNotProd")!,
            detail: .init(uriString: "", portalImage: .Public(imageId: "", fileName: "", host: ""), fileName: ""))
        }

      default:
        return
      }
    }
  }

  static var previews: some View {
    DepositRecordDetailView(
      viewModel: ViewModel(status: .floating),
      playerConfig: PlayerConfigurationImpl(supportLocale: .China()),
      transactionId: "")

    DepositRecordDetailView(
      viewModel: ViewModel(status: .pending),
      playerConfig: PlayerConfigurationImpl(supportLocale: .China()),
      transactionId: "")
  }
}
