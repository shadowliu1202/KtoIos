import SharedBu
import SwiftUI

struct TurnoverAlert<ViewModel>: View
  where ViewModel:
  TurnoverAlertViewModelProtocol &
  ObservableObject
{
  @Environment(\.presentationMode) var presentation

  @StateObject var viewModel: ViewModel

  let situation: TurnoverAlertDataModel.Situation
  let turnover: TurnOverDetail

  var body: some View {
    ZStack {
      Color.from(.greyScaleDefault, alpha: 0.8)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        LimitSpacer(18)

        Text(Localize.string("common_tip_title_warm"))
          .localized(
            weight: .semibold,
            size: 16,
            color: .greyScaleDefault)

        LimitSpacer(10)

        Separator(color: .greyScaleList, lineWeight: 0.5)

        Info()

        Separator(color: .greyScaleList, lineWeight: 0.5)

        Button(
          action: {
            presentation.wrappedValue.dismiss()
          },
          label: {
            Text(Localize.string("common_determine"))
              .localized(
                weight: .semibold,
                size: 16,
                color: .primaryForLight)
              .frame(maxWidth: .infinity)
          })
          .frame(height: 44)
      }
      .backgroundColor(.greyScaleWhite)
      .cornerRadius(14)
      .padding(.horizontal, 53)
    }
    .environmentObject(viewModel)
    .environment(\.playerLocale, viewModel.locale)
    .onAppear {
      viewModel.prepareForAppear(
        situation: situation,
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
        Text(viewModel.detail.headerTitle)
          .localized(
            weight: .regular,
            size: 14,
            color: .greyScaleDefault)

        TurnoverAlert.Field(
          title: Localize.string("bonus_historyname"),
          content: viewModel.detail.turnoverName)

        TurnoverAlert.Field(
          title: Localize.string("bonus_get_bonus"),
          content: viewModel.detail.receiveAmount)

        TurnoverAlert.Field(
          title: Localize.string("bonus_total_request"),
          content: viewModel.detail.totalBetRequest)

        Separator(color: .greyScaleList, lineWeight: 0.5)

        TurnoverAlert.Field(
          title: Localize.string("bonus_remain_request"),
          content: viewModel.detail.remainBetRequest,
          contentColor: .orangeFF691D)

        TurnoverAlert.Field(
          title: Localize.string("bonus_current_completion", [viewModel.detail.percentage]),
          ratio: viewModel.detail.ratio)
      }
      .padding(.top, 12)
      .padding(.bottom, 14)
      .padding(.horizontal, 16)
    }
  }

  struct Field: View {
    let title: String

    var content = ""
    var contentColor: UIColor = .greyScaleBlack

    var ratio: Double?

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .localized(
            weight: .regular,
            size: 14,
            color: .textSecondary)

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
      situation: .intoGame(gameName: "Test Game"),
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

extension UIColor {
  fileprivate static let orangeFF691D: UIColor = #colorLiteral(red: 1, green: 0.4117647059, blue: 0.1137254902, alpha: 1)
}
