import SwiftUI

extension WalletDetail {
  enum Identifier: String {
    case deleteAccountButton
    case accountStatusText
  }
}

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
              color: .whitePure)

          LimitSpacer(30)

          Text(status)
            .localized(
              weight: .medium,
              size: 16,
              color: .whitePure)
            .id(WalletDetail.Identifier.accountStatusText.rawValue)

          LimitSpacer(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        Separator(color: .gray3C3E40)

        VStack {
          ForEach(models.indices, id: \.self) { index in
            VStack(spacing: 8) {
              LimitSpacer(0)

              DefaultRow(model: models[index])

              Separator(color: .gray3C3E40)
                .visibility(index != models.count - 1 ? .visible : .invisible)
            }
          }
        }
        .padding(.horizontal, 30)

        Separator(color: .gray3C3E40)

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
            .id(WalletDetail.Identifier.deleteAccountButton.rawValue)
        }
        .visibility(deletable ? .visible : .gone)
      }
    }
    .pageBackgroundColor(.black131313)
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
      .pageBackgroundColor(.black131313)
  }
}
