import sharedbu
import SwiftUI

private let maximumAmount: Decimal = 9999999

extension WithdrawalCryptoRequestStep1View {
  enum Identifier: String {
    case currencyRatioNotify
  }
}

struct WithdrawalCryptoRequestStep1View<ViewModel>: View
  where ViewModel:
  WithdrawalCryptoRequestStep1ViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  private let cryptoWallet: WithdrawalDto.CryptoWallet
  private let tapAutoFill: (WithdrawalDto.FulfillmentRecipe) -> Void
  private let tapSubmit: (_ confirmInfo: WithdrawalCryptoRequestConfirmDataModel.SetupModel?) -> Void

  init(
    viewModel: ViewModel,
    cryptoWallet: WithdrawalDto.CryptoWallet,
    tapAutoFill: @escaping (WithdrawalDto.FulfillmentRecipe) -> Void,
    tapSubmit: @escaping (_ confirmInfo: WithdrawalCryptoRequestConfirmDataModel.SetupModel?) -> Void)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.cryptoWallet = cryptoWallet
    self.tapAutoFill = tapAutoFill
    self.tapSubmit = tapSubmit
  }

  var body: some View {
    SafeAreaReader {
      ScrollView(showsIndicators: false) {
        PageContainer {
          VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
              Text(Localize.string("withdrawal_step1_title_1"))
                .localized(weight: .medium, size: 14, color: .textPrimary)

              Text(Localize.string("withdrawal_step1_title_2"))
                .localized(weight: .semibold, size: 24, color: .textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ExchangeRateInfo()

            RequestInput()

            Text(
              cryptoWallet.remainTurnOver.isPositive ? Localize.string("cps_auto_fill_request") : Localize
                .string("cps_auto_fill_balance"))
              .localized(weight: .medium, size: 14, color: .alert)
              .onTapGesture {
                viewModel.autoFill(recipe: {
                  tapAutoFill($0)
                })
              }
          }

          LimitSpacer(40)

          Button(Localize.string("common_next")) {
            tapSubmit(viewModel.generateRequestConfirmModel())
          }
          .buttonStyle(ConfirmRed(size: 16))
          .disabled(viewModel.submitButtonDisable)
        }
      }
      .environmentObject(viewModel)
      .padding(.horizontal, 30)
      .pageBackgroundColor(.greyScaleDefault)
      .onPageLoading(
        viewModel.exchangeRateInfo == nil ||
          viewModel.requestInfo == nil)
      .onAppear(perform: {
        viewModel.fetchExchangeRate(cryptoWallet: cryptoWallet)
      })
      .onViewDidLoad {
        viewModel.setup()
      }
    }
  }
}

extension WithdrawalCryptoRequestStep1View {
  struct ExchangeRateInfo: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(Localize.string("cps_excahange_rate"))
          .localized(weight: .semibold, size: 16, color: .textPrimary)

        VStack(alignment: .leading, spacing: 8) {
          if let exchangeRate = viewModel.exchangeRateInfo {
            HStack(spacing: 8) {
              Image(uiImage: exchangeRate.icon)

              Text(exchangeRate.typeNetwork)
                .localized(weight: .regular, size: 12, color: .textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(exchangeRate.rate)
              .localized(weight: .medium, size: 16, color: .textPrimary)

            Text(exchangeRate.ratio)
              .localized(weight: .regular, size: 12, color: .textPrimary)
          }
        }
        .padding(.all, 16)
        .backgroundColor(.greyScaleChatWindow)
        .cornerRadius(6)
      }
    }
  }

  struct RequestInput: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        if let requestInfo = viewModel.requestInfo {
          VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 16) {
              WithdrawalCryptoRequestStep1View.InputRow(
                icon: requestInfo.crypto.flagIcon,
                text: .init(
                  get: {
                    self.viewModel.outPutCryptoAmount
                  },
                  set: {
                    self.viewModel.inputCryptoAmount = $0
                  }),
                textFieldType: CurrencyType(
                  regex: .withDecimal(8),
                  maxAmount: maximumAmount),
                cryptoName: requestInfo.crypto.name)

              Separator(color: .textPrimary, lineWeight: 0.5)

              WithdrawalCryptoRequestStep1View.InputRow(
                icon: requestInfo.fiat.flagIcon,
                text: .init(
                  get: {
                    self.viewModel.outPutFiatAmount
                  },
                  set: {
                    self.viewModel.inputFiatAmount = $0
                  }),
                textFieldType: CurrencyType(
                  regex: .withDecimal(2),
                  maxAmount: maximumAmount),
                cryptoName: requestInfo.fiat.name)
            }
            .padding(.all, 16)
            .strokeBorder(color: viewModel.inputErrorText.isEmpty ? .textPrimary : .alert, cornerRadius: 6)

            Text(viewModel.inputErrorText)
              .localized(weight: .regular, size: 12, color: .alert)
              .visibility(viewModel.inputErrorText.isEmpty ? .gone : .visible)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(Localize.string(
              "withdrawal_amount_range",
              requestInfo.singleCashMinimum,
              requestInfo.singleCashMaximum))
              .localized(weight: .medium, size: 14, color: .textPrimary)

            // FIXME: workaround display vn localize string in preview
            LocalizeText(key: "common_notify_currency_ratio")
              .localized(weight: .medium, size: 14, color: .textPrimary)
              .id(WithdrawalCryptoRequestStep1View.Identifier.currencyRatioNotify.rawValue)
              .visibleLocale([.Vietnam()])
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .onInspected(inspection, self)
    }
  }

  struct InputRow: View {
    @State private var isEditing = false

    let icon: UIImage?
    let text: Binding<String>
    let textFieldType: any TextFieldType
    let cryptoName: String

    var body: some View {
      HStack(spacing: 16) {
        Image(uiImage: icon)

        UIKitTextField(
          text: text,
          isFirstResponder: $isEditing,
          showPassword: .constant(false),
          isPasswordType: false,
          textFieldType: textFieldType,
          initConfiguration: { uiTextField in
            uiTextField.textAlignment = .right
            uiTextField.font = UIFont(name: "PingFangSC-Medium", size: 14)
          },
          updateConfiguration: { uiTextField in
            uiTextField.textColor = isEditing ? .greyScaleWhite : .textPrimary
          })
          .onTapGesture {
            isEditing = true
          }

        Text(cryptoName)
          .localized(weight: .regular, size: 12, color: .textPrimary)
      }
    }
  }
}

struct WithdrawalCryptoRequestStep1View_Previews: PreviewProvider {
  class ViewModel:
    WithdrawalCryptoRequestStep1ViewModelProtocol,
    ObservableObject
  {
    var outPutFiatAmount = ""
    var outPutCryptoAmount = ""
    var ignoreFiatChange = false
    var ignoreCryptoChange = false
    var inputFiatAmount = "123"
    var inputCryptoAmount = "456"
    var supportLocale: SupportLocale = .China()
    var cryptoWallet: WithdrawalDto.CryptoWallet?
    var inputErrorText = "您的提现金额超过单笔限额"
    var submitButtonDisable = true
    var exchangeRateInfo: WithdrawalCryptoRequestDataModel.ExchangeRateInfo? =
      .init(
        icon: UIImage(named: "IconCryptoMain_ETH"),
        typeNetwork: "ETH TRC20",
        rate: "2,589.000049",
        ratio: "1 ETH = 2,589.000049 CNY")

    var requestInfo: WithdrawalCryptoRequestDataModel.RequestInfo? =
      .init(
        fiat: "0".toAccountCurrency(),
        crypto: "0".toCryptoCurrency(supportCryptoType: .usdc),
        singleCashMinimum: "25",
        singleCashMaximum: "150")

    func setup() { }
    func fetchExchangeRate(cryptoWallet _: WithdrawalDto.CryptoWallet) { }
    func autoFill(recipe _: @escaping (WithdrawalDto.FulfillmentRecipe) -> Void) { }
    func generateRequestConfirmModel() -> WithdrawalCryptoRequestConfirmDataModel.SetupModel? {
      nil
    }

    func fillAmounts(accountCurrency _: AccountCurrency, cryptoAmount _: CryptoCurrency) { }
  }

  struct Preview: View {
    let wallet: WithdrawalDto.CryptoWallet =
      .init(
        name: "WalletName",
        walletId: "walletId",
        isDeletable: false,
        verifyStatus: .verified,
        type: .eth,
        network: .erc20,
        address: "walletAdress",
        limitation: .init(
          maxCount: 10,
          maxAmount: "5000".toAccountCurrency(),
          currentCount: 2,
          currentAmount: "100".toAccountCurrency(),
          oneOffMinimumAmount: "20".toAccountCurrency(),
          oneOffMaximumAmount: "600".toAccountCurrency()),
        remainTurnOver: "333".toAccountCurrency())

    var body: some View {
      WithdrawalCryptoRequestStep1View(
        viewModel: ViewModel(),
        cryptoWallet: wallet,
        tapAutoFill: { _ in },
        tapSubmit: { _ in })
    }
  }

  static var previews: some View {
    Preview()
      .environment(\.playerLocale, .Vietnam())
  }
}
