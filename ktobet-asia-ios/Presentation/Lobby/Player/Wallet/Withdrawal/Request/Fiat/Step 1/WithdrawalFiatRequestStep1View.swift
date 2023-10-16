import sharedbu
import SwiftUI

struct WithdrawalFiatRequestStep1View<ViewModel>: View
  where ViewModel:
  WithdrawalFiatRequestStep1ViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  let wallet: WithdrawalDto.FiatWallet

  var onRealNameClick: ((_ editable: Bool) -> Void)?
  var toStep2: (() -> Void)?

  var body: some View {
    SafeAreaReader {
      ScrollView(showsIndicators: false) {
        PageContainer {
          VStack(spacing: 8) {
            Text(key: "withdrawal_step1_title_1")
              .localized(
                weight: .medium,
                size: 14,
                color: .textPrimary)
              .frame(maxWidth: .infinity, alignment: .leading)

            Text(key: "withdrawal_step1_title_2")
              .localized(
                weight: .semibold,
                size: 24,
                color: .textPrimary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 30)

          LimitSpacer(30)

          VStack(alignment: .leading, spacing: 12) {
            SwiftUIInputText(
              placeHolder: Localize.string("common_realname"),
              textFieldText: .constant(viewModel.realNameInfo?.name ?? ""),
              featureType: .lock,
              textFieldType: GeneralType(),
              disableInput: true)
              .disabled(true)
              .onTapGesture {
                guard let editable = viewModel.realNameInfo?.editable
                else {
                  return
                }

                onRealNameClick?(editable)
              }

            SwiftUIInputText(
              placeHolder: Localize.string("withdrawal_amount"),
              textFieldText: $viewModel.amount,
              errorText: viewModel.amountErrorText,
              featureType: .nil,
              textFieldType: CurrencyType(
                regex: .noDecimal,
                maxAmount: 99999999))

            VStack(spacing: 4) {
              Text(
                key: "withdrawal_amount_range",
                viewModel.wallet?.limitation.oneOffMinimumAmount.formatString(sign: .normal) ?? "",
                viewModel.wallet?.limitation.oneOffMaximumAmount.formatString(sign: .normal) ?? "")

              Text(key: "common_notify_currency_ratio")
                .visibleLocale([.Vietnam()])
            }
            .localized(
              weight: .medium,
              size: 14,
              color: .textPrimary)
          }
          .padding(.horizontal, 30)

          LimitSpacer(40)

          Button(
            action: {
              toStep2?()
            },
            label: {
              Text(key: "common_next")
            })
            .disabled(!viewModel.isAllowSubmit)
            .buttonStyle(ConfirmRed(size: 16))
            .padding(.horizontal, 30)
        }
      }
      .environmentObject(viewModel)
      .environment(\.playerLocale, viewModel.supportLocale)
      .onPageLoading(viewModel.wallet == nil || viewModel.realNameInfo == nil)
      .pageBackgroundColor(.greyScaleDefault)
      .onViewDidLoad {
        viewModel.prepareForAppear(wallet: wallet)
      }
    }
  }
}

struct WithdrawalFiatRequestStep1View_Previews: PreviewProvider {
  class ViewModel: WithdrawalFiatRequestStep1ViewModelProtocol, ObservableObject {
    var supportLocale: SupportLocale = .China()
    var realNameInfo: (name: String, editable: Bool)? = ("me", false)
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
    var amountErrorText = ""
    var isAllowSubmit = true
    func prepareForAppear(wallet _: WithdrawalDto.FiatWallet) { }
  }

  static var previews: some View {
    WithdrawalFiatRequestStep1View(viewModel: ViewModel(), wallet: ViewModel().wallet!)
  }
}
