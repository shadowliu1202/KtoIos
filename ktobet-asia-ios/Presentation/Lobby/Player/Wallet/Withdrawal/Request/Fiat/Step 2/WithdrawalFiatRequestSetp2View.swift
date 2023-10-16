import sharedbu
import SwiftUI

struct WithdrawalFiatRequestStep2View<ViewModel>: View
  where ViewModel:
  WithdrawalFiatRequestStep2ViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  let wallet: WithdrawalDto.FiatWallet
  let amount: String

  var onSubmit: (() -> Void)?
  var onSuccess: (() -> Void)?

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(spacing: 8) {
          Text(key: "withdrawal_step2_title_1")
            .localized(
              weight: .medium,
              size: 14,
              color: .textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)

          Text(key: "withdrawal_step2_title_2")
            .localized(
              weight: .semibold,
              size: 24,
              color: .textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 30)

        LimitSpacer(24)

        Separator()

        VStack(spacing: 16) {
          VStack(spacing: 8) {
            DefaultRow(
              common: .init(
                title: Localize.string("common_transactionamount"),
                content: viewModel.amount.toAccountCurrency().formatString()))
              .padding(.top, 8)

            Separator()
          }
          .padding(.horizontal, 30)

          VStack {
            VStack(spacing: 8) {
              if let limitation = viewModel.wallet?.limitation {
                Text(key: "withdrawal_step2_afterwithdrawal")
                  .localized(
                    weight: .medium,
                    size: 16,
                    color: .textPrimary)
                  .frame(maxWidth: .infinity, alignment: .leading)

                DefaultRow(
                  common: .init(
                    title: Localize.string("withdrawal_dailywithdrawalcount_2"),
                    content: Localize.string(
                      "common_times_count", "\((limitation.currentCount) - 1)")))

                DefaultRow(
                  common: .init(
                    title: Localize.string("withdrawal_dailywithdrawalamount_2"),
                    content: (limitation.currentAmount - viewModel.amount.toAccountCurrency()).abs().formatString()))
              }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
          }
          .stroke(color: .greyScaleDivider, cornerRadius: 0)
          .padding(.horizontal, 30)

          Separator()

          LimitSpacer(24)

          Button(
            action: {
              onSubmit?()
            },
            label: {
              Text(key: "common_submit")
            })
            .buttonStyle(ConfirmRed(size: 16))
            .padding(.horizontal, 30)
        }
      }
    }
    .environmentObject(viewModel)
    .environment(\.playerLocale, viewModel.supportLocale)
    .onPageLoading(viewModel.wallet == nil)
    .pageBackgroundColor(.greyScaleDefault)
    .onViewDidLoad {
      viewModel.prepareForAppear(wallet: wallet, amount: amount)
    }
    .onChange(of: viewModel.isSubmitSuccess) { newValue in
      guard newValue else { return }
      onSuccess?()
    }
  }
}

struct WithdrawalFiatRequestStep2View_Previews: PreviewProvider {
  class ViewModel: WithdrawalFiatRequestStep2ViewModelProtocol, ObservableObject {
    var supportLocale: SupportLocale = .China()
    var wallet: WithdrawalDto.FiatWallet? = .init(
      walletId: "test123",
      name: "Test 123",
      isDeletable: true,
      verifyStatus: .verified,
      bankAccount: .init(
        bankId: 0,
        branch: "",
        accountName: "",
        accountNumber: "",
        city: "",
        location: ""),
      limitation: .init(
        maxCount: 100,
        maxAmount: "1000".toAccountCurrency(),
        currentCount: 3,
        currentAmount: "10000".toAccountCurrency(),
        oneOffMinimumAmount: "10".toAccountCurrency(),
        oneOffMaximumAmount: "1000".toAccountCurrency()))
    var amount = "100"
    var isRealNameEditable = false
    var isSubmitSuccess = false
    var isSubmitDisable = false
    func prepareForAppear(wallet _: WithdrawalDto.FiatWallet, amount _: String) { }
    func submitWithdrawal() { }
  }

  static var previews: some View {
    WithdrawalFiatRequestStep2View(
      viewModel: ViewModel(), wallet: ViewModel().wallet!, amount: "100")
  }
}
