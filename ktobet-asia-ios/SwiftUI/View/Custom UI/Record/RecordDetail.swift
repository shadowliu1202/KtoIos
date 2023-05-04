import SwiftUI

struct RecordDetail<Buttons: View>: View {
  let title: String
  let rowTypes: [RecordRow.`Type`]
  let shouldShowUploader: Bool
  let shouldShowButtons: Bool
  let isLoading: Bool
  let buttons: () -> Buttons

  init(
    title: String,
    rowTypes: [RecordRow.`Type`],
    shouldShowUploader: Bool,
    shouldShowButtons: Bool? = nil,
    isLoading: Bool,
    @ViewBuilder buttons: @escaping () -> Buttons = { EmptyView() })
  {
    self.title = title
    self.rowTypes = rowTypes
    self.shouldShowUploader = shouldShowUploader
    self.isLoading = isLoading
    self.buttons = buttons

    if let shouldShowButtons {
      self.shouldShowButtons = shouldShowButtons
    }
    else {
      self.shouldShowButtons = shouldShowUploader
    }
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        Text(title)
          .localized(
            weight: .semibold,
            size: 24,
            color: .whitePure)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 30)

        LimitSpacer(30)

        Separator(color: .gray3C3E40)

        VStack(spacing: 0) {
          ForEach(rowTypes.indices, id: \.self) {
            LimitSpacer(8)

            RecordRow(
              type: rowTypes[$0],
              shouldShowBottomLine: $0 != rowTypes.count - 1,
              shouldShowUploader: shouldShowUploader)
          }
          .padding(.horizontal, 30)

          if shouldShowButtons {
            LimitSpacer(24)
            buttons()
              .padding(.horizontal, 30)
          }
          else {
            LimitSpacer(40)
            Separator(color: .gray3C3E40)
          }
        }
      }
    }
    .onPageLoading(isLoading)
    .pageBackgroundColor(.gray131313)
  }
}
