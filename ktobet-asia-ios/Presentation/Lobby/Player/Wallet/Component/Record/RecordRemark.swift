import sharedbu
import SwiftUI

@available(*, deprecated, message: "Waiting for refactor.")
struct RecordRemark: View {
  struct Configuration {
    let previous: [Previous.Model]
    @Binding var uploader: [Uploader.Model]

    var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?
    var onUpload: (() -> Void)?

    var imagesOnSend: (() -> Void)?
    var isAllowSendImages: Bool

    var isDeposit: Bool
  }

  let config: Configuration
  let shouldShowUploader: Bool

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 2) {
        Text(Localize.string("common_remark"))
          .localized(
            weight: .regular,
            size: 12,
            color: .textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)

        Previous(models: config.previous, onClickImage: config.onClickImage)
      }

      if shouldShowUploader {
        LimitSpacer(24)

        Uploader(
          models: config.$uploader,
          onUpload: config.onUpload,
          imagesOnSend: config.imagesOnSend,
          isAllowSendImages: config.isAllowSendImages,
          isDeposit: config.isDeposit)
      }
      else {
        LimitSpacer(16)
      }
    }
  }
}

// MARK: - Previous

extension RecordRemark {
  struct Previous: View {
    struct Model {
      let date: String
      let content: String
      var uploadedURLs: [(url: String, thumbnail: String)] = []
    }

    let models: [Model]
    
    var onClickImage: ((_ urlString: String, _ image: UIImage) -> Void)?

    var body: some View {
      VStack(spacing: 18) {
        ForEach(models.indices, id: \.self) {
          let model = models[$0]

          VStack(spacing: 12) {
            DefaultRow(common: .init(date: model.date, content: model.content))

            HStack(spacing: 12) {
              ForEach(0...2, id: \.self) { index in
                let uploaded = model.uploadedURLs[safe: index]

                if let uploaded {
                  Color.from(.greyScaleSidebar)
                    .cornerRadius(4)
                    .strokeBorder(color: .greyScaleDivider, cornerRadius: 4)
                    .frame(height: 96)
                    .overlay(
                      LazyImage(url: uploaded.thumbnail) { image in
                        Image(uiImage: image)
                          .resizable()
                          .scaledToFit()
                          .onTapGesture {
                            onClickImage?(uploaded.url, image)
                          }
                      })
                }
                else { Rectangle().fill(Color.clear) }
              }
            }
            .visibility(model.uploadedURLs.isEmpty ? .gone : .visible)
          }
        }
      }
    }
  }

  // MARK: - Uploader

  struct Uploader: View {
    struct Model: Equatable {
      let image: UIImage

      var isUploading = true
      var detail: UploadImageDetail?

      static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.image == rhs.image
      }
    }

    @Binding var models: [Model]

    var onUpload: (() -> Void)?

    var imagesOnSend: (() -> Void)?
    var isAllowSendImages: Bool

    var isDeposit: Bool

    var body: some View {
      VStack(spacing: 0) {
        VStack(spacing: 12) {
          Text(Localize.string("common_upload_file"))
            .localized(
              weight: .regular,
              size: 16,
              color: .greyScaleWhite)
            .frame(maxWidth: .infinity, alignment: .leading)

          ForEach(models.indices, id: \.self) { index in
            let selected = models[index]

            ZStack(alignment: .topLeading) {
              Image(uiImage: selected.image)
                .resizable()
                .scaledToFit()
                .frame(height: 192)
                .frame(maxWidth: .infinity)
                .strokeBorder(color: .greyScaleDivider, cornerRadius: 10)
                .backgroundColor(.greyScaleSidebar)
                .cornerRadius(10)
                .allowsHitTesting(false)
                .overlay(
                  SwiftUIGradientArcView(
                    isVisible: selected.isUploading)
                    .frame(width: 30, height: 30))

              Button(
                action: {
                  guard let index = models.firstIndex(of: selected) else { return }
                  models.remove(at: index)
                },
                label: {
                  Text(Localize.string("common_remove"))
                    .localized(
                      weight: .medium,
                      size: 14,
                      color: .greyScaleWhite)
                    .frame(width: 52, height: 32)
                })
                .backgroundColor(.greyScaleBlack, alpha: 0.5)
                .cornerRadius(10)
                .alignmentGuide(.leading, computeValue: { $0[.leading] - 12 })
                .alignmentGuide(.top, computeValue: { $0[.top] - 12 })
            }
          }

          Button(
            action: {
              onUpload?()
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
                    color: .textPrimary)
                  .frame(maxWidth: .infinity, alignment: .leading)

                Image("iconChevronRight16")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 16, height: 16)
              }
              .padding(.horizontal, 17)
            })
            .frame(maxWidth: .infinity, minHeight: 48)
            .backgroundColor(.inputDefault)
            .cornerRadius(4)

          Text(Localize.string("common_photo_upload_limit"))
            .localized(
              weight: .medium,
              size: 14,
              color: .textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }

        LimitSpacer(40)

        if isDeposit {
          Button(
            action: {
              imagesOnSend?()
            },
            label: {
              Text(Localize.string("common_submit"))
            })
            .buttonStyle(.confirmRed(size: 16))
            .disabled(!isAllowSendImages)
        }
        else {
          Button(
            action: {
              imagesOnSend?()
            },
            label: {
              Text(Localize.string("common_submit"))
            })
            .buttonStyle(.clearBorder)
            .disabled(!isAllowSendImages)
        }
      }
    }
  }
}

// MARK: - Convert from ShareBu

extension RecordRemark.Previous.Model {
  init(
    updateHistory: UpdateHistory,
    host: String,
    uploadedURLs: [(url: String, thumbnail: String)]? = nil)
  {
    self.date = updateHistory.createdDate.toDateTimeString()

    if let uploadedURLs {
      self.uploadedURLs = uploadedURLs
    }
    else {
      self.uploadedURLs = Array(updateHistory.imageIds.prefix(3))
        .map {
          (url: host + $0.path(), thumbnail: host + $0.thumbnailPath() + ".jpg")
        }
    }

    self.content = [
      updateHistory.remarkLevel1,
      updateHistory.remarkLevel2,
      updateHistory.remarkLevel3
    ]
    .filter { !$0.isEmpty }
    .joined(separator: " > ")
  }
}
