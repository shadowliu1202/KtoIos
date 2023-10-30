import sharedbu
import SwiftUI

struct WithdrawalCryptoRequestStep2View<ViewModel>: View
  where ViewModel:
  WithdrawalCryptoRequestStep2ViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  let model: WithdrawalCryptoRequestConfirmDataModel.SetupModel?
  let submitSuccess: () -> Void

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(alignment: .leading, spacing: 8) {
          Text(Localize.string("withdrawal_step2_title_1"))
            .localized(weight: .medium, size: 14, color: .textPrimary)

          Text(Localize.string("withdrawal_step2_title_2"))
            .localized(weight: .semibold, size: 24, color: .textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        LimitSpacer(24)

        Info()

        LimitSpacer(40)

        PrimaryButton(
          title: Localize.string("common_submit"),
          action: {
            viewModel.requestCryptoWithdrawalTo {
              submitSuccess()
            }
          })
          .padding(.horizontal, 30)
          .disabled(viewModel.submitDisable)
      }
    }
    .environmentObject(viewModel)
    .pageBackgroundColor(.greyScaleDefault)
    .onViewDidLoad {
      viewModel.setup(model: model)
    }
  }
}

extension WithdrawalCryptoRequestStep2View {
  struct Info: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
      VStack(spacing: 16) {
        VStack(spacing: 8) {
          Separator()

          ForEach(viewModel.requestInfo.indices, id: \.self) { index in
            VStack(spacing: 8) {
              DefaultRow(model: viewModel.requestInfo[index])

              Separator()
            }
          }
          .padding(.horizontal, 30)
        }

        VStack {
          VStack(alignment: .leading, spacing: 0) {
            LimitSpacer(8)

            Text(Localize.string("withdrawal_step2_afterwithdrawal"))
              .localized(weight: .medium, size: 16, color: .textPrimary)

            LimitSpacer(24)

            ForEach(viewModel.afterInfo.indices, id: \.self) { index in
              if index != 0 {
                LimitSpacer(8)
              }
              DefaultRow(model: viewModel.afterInfo[index])
            }
          }
          .padding(16)
          .stroke(color: .greyScaleDivider, cornerRadius: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        Separator()
      }
    }
  }
}

struct WithdrawalCryptoRequestStep2View_Previews: PreviewProvider {
  class ViewModel:
    WithdrawalCryptoRequestStep2ViewModelProtocol,
    ObservableObject
  {
    var submitDisable = false

    var requestInfo: [DefaultRow.Common] = (0...4)
      .map {
        .init(
          title: "R_Title \($0)",
          content: "R_Content \($0)")
      }

    var afterInfo: [DefaultRow.Common] = (0...3)
      .map {
        .init(
          title: "A_Title \($0)",
          content: "A_Content \($0)")
      }

    func setup(model _: WithdrawalCryptoRequestConfirmDataModel.SetupModel?) { }
    func requestCryptoWithdrawalTo(_: @escaping () -> Void) { }
    func getSupportLocale() -> SupportLocale {
      .China()
    }
  }

  struct Preview: View {
    var body: some View {
      WithdrawalCryptoRequestStep2View(
        viewModel: ViewModel(),
        model: nil,
        submitSuccess: { })
    }
  }

  static var previews: some View {
    Preview()
  }
}
