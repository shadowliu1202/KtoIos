import SwiftUI

extension WalletDetail {
  enum Identifier: String {
    case deleteAccountButton
    case accountStatusText
  }
}

@available(*, deprecated, message: "Waiting for refactor.")
struct WalletDetail: View {
  let models: [DefaultRow.Common]
  let status: String
  let deletable: Bool
  let deleteActionDisable: Bool

  var onDelete: (() -> Void)?

  var inspection = Inspection<Self>()

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        Group {
          Text(key: "withdrawal_bankaccountdetail_title")
            .localized(
              weight: .semibold,
              size: 24,
              color: .greyScaleWhite)

          LimitSpacer(30)

          Text(status)
            .localized(
              weight: .medium,
              size: 16,
              color: .greyScaleWhite)
            .id(WalletDetail.Identifier.accountStatusText.rawValue)

          LimitSpacer(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        Separator()

        VStack {
          ForEach(models.indices, id: \.self) { index in
            VStack(spacing: 8) {
              LimitSpacer(0)

              DefaultRow(model: models[index])

              Separator()
                .visibility(index != models.count - 1 ? .visible : .invisible)
            }
          }
        }
        .padding(.horizontal, 30)

        Separator()

        Group {
          LimitSpacer(40)

          Button(
            action: {
              onDelete?()
            },
            label: {
              Text(key: "withdrawal_bankcard_delete")
            })
            .buttonStyle(ConfirmRed(size: 16))
            .disabled(deleteActionDisable)
            .padding(.horizontal, 30)
        }
        .visibility(deletable ? .visible : .gone)
        .id(WalletDetail.Identifier.deleteAccountButton.rawValue)
      }
    }
    .pageBackgroundColor(.greyScaleDefault)
    .onInspected(inspection, self)
  }
}

struct WalletDetail_Previews: PreviewProvider {
  static var previews: some View {
    WalletDetail(
      models: (0...5).map { .init(title: "title \($0)", content: "content \($0)") },
      status: "本账户已验证核可",
      deletable: true,
      deleteActionDisable: true)
      .pageBackgroundColor(.greyScaleDefault)
  }
}
