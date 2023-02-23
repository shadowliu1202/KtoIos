import SharedBu
import SwiftUI

struct TurnoverAlert<ViewModel>: View
  where ViewModel: TurnoverAlertViewModelProtocol & ObservableObject
{
  @StateObject var viewModel: ViewModel
  @Environment(\.presentationMode) var presentation

  let gameName: String
  let turnover: TurnOverDetail

  var body: some View {
    ZStack {
      Color.from(.gray131313, alpha: 0.8)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        LimitSpacer(18)

        Text(Localize.string("common_tip_title_warm"))
          .localized(
            weight: .semibold,
            size: 16,
            color: .gray131313)

        LimitSpacer(10)

        Separator(color: .gray3F3F3F, lineWeight: 0.5)

        Info()

        Separator(color: .gray3F3F3F, lineWeight: 0.5)

        Button(
          action: {
            presentation.wrappedValue.dismiss()
          },
          label: {
            Text(Localize.string("common_determine"))
              .localized(
                weight: .semibold,
                size: 16,
                color: .redD90101)
              .frame(maxWidth: .infinity)
          })
          .frame(height: 44)
      }
      .backgroundColor(.whitePure)
      .cornerRadius(14)
      .frame(width: 270)
    }
    .environmentObject(viewModel)
    .environment(\.playerLocale, viewModel.locale)
    .onAppear {
      viewModel.prepareForAppear(
        gameName: gameName,
        turnover: turnover)
    }
  }
}

// MARK: - Component

extension TurnoverAlert {
  struct Info: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text(
          String(
            format: Localize.string("product_turnover_description"),
            arguments: [
              viewModel.detail.gameName,
              viewModel.detail.receiveBonusDate
            ]))
            .localized(
              weight: .regular,
              size: 14,
              color: .gray131313)

        TurnoverAlert.Field(
          title: Localize.string("bonus_historyname"),
          content: viewModel.detail.turnoverName)

        TurnoverAlert.Field(
          title: Localize.string("bonus_get_bonus"),
          content: viewModel.detail.receiveAmount)

        TurnoverAlert.Field(
          title: Localize.string("bonus_total_request"),
          content: viewModel.detail.totoalBetRequest)

        Separator(color: .gray3F3F3F, lineWeight: 0.5)

        TurnoverAlert.Field(
          title: Localize.string("bonus_remain_request"),
          content: viewModel.detail.remainBetRequest,
          contentColor: .orangeFF691D)

        TurnoverAlert.Field(
          title: Localize.string("bonus_current_completion", [viewModel.detail.percentage]),
          ratio: viewModel.detail.ratio)
      }
      .padding(.vertical, 14)
      .padding(.horizontal, 16)
    }
  }

  struct Field: View {
    let title: String

    var content = ""
    var contentColor: UIColor = .blackPure

    var ratio: Double?

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .localized(
            weight: .regular,
            size: 14,
            color: .gray595959)

        if let ratio {
          BarProgressView(to: ratio)
            .frame(height: 16)
        }
        else {
          Text(content)
            .localized(
              weight: .medium,
              size: 14,
              color: contentColor)
        }
      }
    }
  }
}

struct TurnoverAlert_Previews: PreviewProvider {
  static var previews: some View {
    TurnoverAlert(
      viewModel: TurnoverAlertViewModel(locale: .China()),
      gameName: "Test Game",
      turnover: .init(
        achieved: "".toAccountCurrency(),
        formula: "",
        informPlayerDate: Date().toUTCOffsetDateTime(),
        name: "Test bonus",
        bonusId: "",
        remainAmount: "9527".toAccountCurrency(),
        parameters: .init(
          amount: "100.00".toAccountCurrency(),
          balance: "".toAccountCurrency(),
          betMultiplier: 0,
          capital: "".toAccountCurrency(),
          depositRequest: "".toAccountCurrency(),
          percentage: .init(percent: 87.87),
          request: "".toAccountCurrency(),
          requirement: "".toAccountCurrency(),
          turnoverRequest: "95270".toAccountCurrency())))
  }
}
