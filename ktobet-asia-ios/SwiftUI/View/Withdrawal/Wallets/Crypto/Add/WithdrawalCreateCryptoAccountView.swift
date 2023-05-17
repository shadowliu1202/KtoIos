import SharedBu
import SwiftUI

struct WithdrawalCreateCryptoAccountView<ViewModel>: View
  where ViewModel:
  WithdrawalCreateCryptoAccountViewModelProtocol &
  ObservableObject
{
  enum CurrentFocus {
    case currency
    case network
  }

  @StateObject private var viewModel: ViewModel

  @State var currentFocus: CurrentFocus?

  private let readQRCodeButtonOnTap: (() -> Void)?
  private let createAccountOnSuccess: ((_ bankCardId: String) -> Void)?

  init(
    viewModel: ViewModel,
    readQRCodeButtonOnTap: (() -> Void)? = nil,
    createAccountOnSuccess: ((_ bankCardID: String) -> Void)? = nil)
  {
    self._viewModel = .init(wrappedValue: viewModel)

    self.readQRCodeButtonOnTap = readQRCodeButtonOnTap
    self.createAccountOnSuccess = createAccountOnSuccess
  }

  var body: some View {
    SafeAreaReader(ignoresSafeArea: .all) {
      ScrollView(showsIndicators: false) {
        PageContainer {
          VStack(spacing: 30) {
            Text(Localize.string("withdrawal_addaccount"))
              .localized(weight: .semibold, size: 24, color: .whitePure)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 40) {
              VStack(spacing: 12) {
                SwiftUIDropDownText(
                  placeHolder: Localize.string("cps_crypto_currency"),
                  textFieldText: $viewModel.selectedCryptoType,
                  items: viewModel.cryptoTypes,
                  featureType: .select,
                  shouldBeFocus: currentFocus == .currency,
                  onTapGesture: {
                    currentFocus = .currency
                  })

                SwiftUIDropDownText(
                  placeHolder: Localize.string("cps_crypto_network"),
                  textFieldText: $viewModel.selectedCryptoNetwork,
                  items: viewModel.cryptoNetworks,
                  featureType: .select,
                  shouldBeFocus: currentFocus == .network,
                  onTapGesture: {
                    currentFocus = .network
                  })

                SwiftUIInputText(
                  placeHolder: Localize.string("cps_crypto_account_name"),
                  textFieldText: $viewModel.accountAlias,
                  errorText: viewModel.aliasVerifyErrorText,
                  textFieldType: GeneralType())

                SwiftUIInputText(
                  placeHolder: Localize.string("cps_wallet_address"),
                  textFieldText: $viewModel.accountAddress,
                  errorText: viewModel.addressVerifyErrorText,
                  featureType: .qrCode({
                    readQRCodeButtonOnTap?()
                  }),
                  textFieldType: GeneralType(regex: .numberAndEnglish))
              }
              .zIndex(1)

              Button(
                action: {
                  viewModel.createCryptoAccount(onSuccess: createAccountOnSuccess)
                },
                label: {
                  Text(Localize.string("cps_add_account"))
                })
                .buttonStyle(.confirmRed)
                .disabled(!viewModel.isCreateAccountEnable)
            }
          }
          .padding(.horizontal, 30)
        }
      }
    }
    .onPageLoading(viewModel.isLoading)
    .pageBackgroundColor(.black131313)
    .onAppear(perform: viewModel.setup)
  }
}

struct WithdrawalCreateCryptoAccountView_Previews: PreviewProvider {
  class FakeViewModel:
    WithdrawalCreateCryptoAccountViewModelProtocol,
    ObservableObject
  {
    @Published private(set) var cryptoTypes: [String] = ["USDT", "ETH"]
    @Published private(set) var cryptoNetworks = ["TRC20"]

    @Published private(set) var addressVerifyErrorText = ""
    @Published private(set) var aliasVerifyErrorText = ""

    @Published private(set) var isCreateAccountEnable = false

    @Published private(set) var isLoading = false

    @Published var selectedCryptoType = "USDT"
    @Published var selectedCryptoNetwork = "TRC20"

    @Published var accountAlias = "虚拟币钱包1"
    @Published var accountAddress = ""

    func setup() { }

    func readQRCode(image _: UIImage?, onFailure _: (() -> Void)?) { }

    func createCryptoAccount(onSuccess _: ((_ bankCardId: String) -> Void)?) { }

    func getSupportLocale() -> SupportLocale { .China() }
  }

  static var previews: some View {
    WithdrawalCreateCryptoAccountView(viewModel: FakeViewModel())
  }
}
