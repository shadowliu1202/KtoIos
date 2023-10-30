import sharedbu
import SwiftUI

extension WithdrawalAddFiatBankCardView {
  enum Identifier: String {
    case usernameTextField
  }
}

struct WithdrawalAddFiatBankCardView<ViewModel>: View
  where ViewModel: WithdrawalAddFiatBankCardViewModelProtocol & ObservableObject
{
  @StateObject var viewModel: ViewModel

  let tapUserName: (_ editable: Bool) -> Void
  let submitSuccess: () -> Void

  var body: some View {
    SafeAreaReader {
      ScrollView(showsIndicators: false) {
        PageContainer {
          VStack(spacing: 40) {
            VStack(spacing: 30) {
              Text(Localize.string("withdrawal_addaccount"))
                .localized(weight: .semibold, size: 24, color: .greyScaleWhite)
                .frame(maxWidth: .infinity, alignment: .leading)

              Info(tapUserName: tapUserName)
            }
            .zIndex(1)

            PrimaryButton(
              title: Localize.string("withdrawal_setbankaccount_button"),
              action: {
                viewModel.addWithdrawalAccount {
                  submitSuccess()
                }
              })
              .disabled(viewModel.isSubmitButtonDisable)
          }
        }
      }
      .onPageLoading(
        viewModel.isRealNameEditable == nil ||
          viewModel.bankNames == nil)
      .environmentObject(viewModel)
      .padding(.horizontal, 30)
      .pageBackgroundColor(.greyScaleDefault)
      .onViewDidLoad {
        viewModel.setup()
      }
    }
  }
}

extension WithdrawalAddFiatBankCardView {
  struct Info: View {
    @EnvironmentObject var viewModel: ViewModel

    @State var isKeyboardPresented = false

    let tapUserName: (_ editable: Bool) -> Void

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(spacing: 12) {
        if
          let isRealNameEditable = viewModel.isRealNameEditable,
          let bankNames = viewModel.bankNames
        {
          SwiftUIInputText(
            placeHolder: Localize.string("withdrawal_accountrealname"),
            textFieldText: .constant(viewModel.userName),
            featureType: .lock,
            textFieldType: GeneralType(),
            disableInput: true)
            .disabled(true)
            .onTapGesture {
              tapUserName(isRealNameEditable)
            }
            .id(WithdrawalAddFiatBankCardView.Identifier.usernameTextField.rawValue)

          SwiftUIDropDownText(
            placeHolder: Localize.string("withdrawal_bank_name"),
            textFieldText: $viewModel.selectedBank,
            errorText: viewModel.bankError,
            items: bankNames,
            featureType: .inputAssisted,
            dropDownArrowVisible: false)

          SwiftUIInputText(
            placeHolder: Localize.string("withdrawal_branch"),
            textFieldText: $viewModel.inputBranch,
            errorText: viewModel.branchError,
            textFieldType: GeneralType())

          SwiftUIDropDownText(
            placeHolder: Localize.string("withdrawal_bankstate"),
            textFieldText: $viewModel.selectedProvince,
            errorText: viewModel.provinceError,
            items: viewModel.provinces,
            featureType: .inputValidated)

          SwiftUIDropDownText(
            placeHolder: Localize.string("withdrawal_bankcity"),
            textFieldText: $viewModel.selectedCity,
            errorText: viewModel.cityError,
            items: viewModel.countries,
            featureType: .inputValidated)
            .disabled(viewModel.isCitySelectorDisable)
            .opacity(viewModel.isCitySelectorDisable ? 0.5 : 1)

          SwiftUIInputText(
            placeHolder: Localize.string("withdrawal_accountnumber"),
            textFieldText: $viewModel.inputAccountNumber,
            errorText: viewModel.accountNumberError,
            textFieldType: GeneralType(
              regex: .number,
              keyboardType: .numberPad,
              maxLength: viewModel.accountNumberMaxLength))
        }
      }
      .onInspected(inspection, self)
    }
  }
}

struct WithdrawalAddFiatBankCardView_Previews: PreviewProvider {
  class ViewModel:
    WithdrawalAddFiatBankCardViewModelProtocol,
    ObservableObject
  {
    @Published var userName = "李嘉诚"
    @Published var isRealNameEditable: Bool? = false
    @Published var bankNames: [String]? = ["bank1", "bank2"]
    @Published var provinces: [String] = ["province1", "province2"]
    @Published var countries: [String] = ["city1", "city2"]
    @Published var bankError = "empty"
    @Published var branchError = "empty"
    @Published var provinceError = "empty"
    @Published var cityError = "empty"
    @Published var accountNumberError = "empty"
    @Published var selectedBank = "bank1"
    @Published var inputBranch = "branch1"
    @Published var selectedProvince = ""
    @Published var selectedCity = ""
    @Published var inputAccountNumber = ""
    var accountNumberMaxLength = 10
    var isCitySelectorDisable = false
    @Published var isSubmitButtonDisable = false

    func setup() { }
    func addWithdrawalAccount(_: () -> Void) { }
    func getSupportLocale() -> SupportLocale {
      .Vietnam()
    }
  }

  static var previews: some View {
    WithdrawalAddFiatBankCardView(
      viewModel: ViewModel(),
      tapUserName: { _ in },
      submitSuccess: { })
  }
}
