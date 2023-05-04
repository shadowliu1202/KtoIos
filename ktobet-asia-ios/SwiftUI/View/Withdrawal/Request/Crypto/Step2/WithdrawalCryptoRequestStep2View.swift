import SharedBu
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
            .localized(weight: .medium, size: 14, color: .gray9B9B9B)

          Text(Localize.string("withdrawal_step2_title_2"))
            .localized(weight: .semibold, size: 24, color: .gray9B9B9B)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        LimitSpacer(24)

        Info()

        LimitSpacer(40)

        Button(Localize.string("common_submit")) {
          viewModel.requestCryptoWithdrawalTo {
            submitSuccess()
          }
        }
        .padding(.horizontal, 30)
        .buttonStyle(ConfirmRed(size: 16))
        .disabled(viewModel.submitDisable)
      }
    }
    .environmentObject(viewModel)
    .pageBackgroundColor(.black131313)
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
          Separator(color: .gray3C3E40)

          ForEach(viewModel.requestInfo.indices, id: \.self) { index in
            VStack(spacing: 8) {
              DefaultRow(
                model: viewModel.requestInfo[index],
                contentLineLimit: nil)

              Separator(color: .gray3C3E40)
            }
          }
          .padding(.horizontal, 30)
        }

        VStack {
          VStack(alignment: .leading, spacing: 0) {
            LimitSpacer(8)

            Text(Localize.string("withdrawal_step2_afterwithdrawal"))
              .localized(weight: .medium, size: 16, color: .gray9B9B9B)

            LimitSpacer(24)

            ForEach(viewModel.afterInfo.indices, id: \.self) { index in
              if index != 0 {
                LimitSpacer(8)
              }
              DefaultRow(model: viewModel.afterInfo[index])
            }
          }
          .padding(16)
          .stroke(color: .gray3C3E40, cornerRadius: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)

        Separator(color: .gray3C3E40)
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
