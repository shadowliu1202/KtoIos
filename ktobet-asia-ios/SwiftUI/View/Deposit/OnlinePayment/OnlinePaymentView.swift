import Combine
import SharedBu
import SwiftUI

extension OnlinePaymentView {
  enum Identifier: String {
    case amountFloatHint
    case vnCurrencyHint
    case instructionLink
    case gatewayCells
    case normalForm
    case onlyAmountForm
    case remittanceButton
  }
}

struct OnlinePaymentView<ViewModel>: View
  where ViewModel:
  OnlinePaymentViewModelProtocol &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel

  @State private var selectedGateway: OnlinePaymentDataModel.Gateway?

  @State private var supportBankName: String? = nil
  @State private var remitterName: String? = nil
  @State private var remitterAccountNumber: String? = nil
  @State private var remitAmount: String? = nil

  private let onlinePaymentDTO: PaymentsDTO.Online?
  private let userGuideOnTap: () -> Void
  private let remitButtonOnSuccess: (_ url: String) -> Void

  private let remitInfoSubject: PassthroughSubject<Void, Never> = .init()

  init(
    viewModel: ViewModel,
    onlinePaymentDTO: PaymentsDTO.Online? = nil,
    userGuideOnTap: @escaping () -> Void,
    remitButtonOnSuccess: @escaping (_ url: String) -> Void)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.onlinePaymentDTO = onlinePaymentDTO
    self.userGuideOnTap = userGuideOnTap
    self.remitButtonOnSuccess = remitButtonOnSuccess
  }

  var body: some View {
    SafeAreaReader {
      VStack(spacing: 0) {
        ScrollView(showsIndicators: false) {
          VStack(spacing: 30) {
            Header(selectedGateway, userGuideOnTap)

            Gateways($selectedGateway)

            RemittanceInfo(
              $supportBankName,
              $remitterName,
              $remitterAccountNumber,
              $remitAmount,
              selectedGateway)
          }
          .padding(.top, 26)
          .padding(.bottom, 40)
        }

        RemittanceButton(
          selectedGateway,
          supportBankName,
          remitterName,
          remitterAccountNumber,
          remitAmount,
          remitButtonOnSuccess)
      }
      .onPageLoading(viewModel.gateways.isEmpty)
      .pageBackgroundColor(.black131313)
      .environmentObject(viewModel)
      .onViewDidLoad {
        viewModel.setupData(onlineDTO: onlinePaymentDTO!)
      }
      .onChange(of: viewModel.gateways) { gateways in
        self.selectedGateway = gateways.first
      }
      .onChange(of: viewModel.remitterName) { remitterName in
        self.remitterName = remitterName
      }
      .onChange(of: selectedGateway) { _ in
        supportBankName = nil
        remitAmount = nil

        remitInfoSubject.send(())
      }
      .onChange(of: supportBankName) { _ in
        remitInfoSubject.send(())
      }
      .onChange(of: remitterName) { _ in
        remitInfoSubject.send(())
      }
      .onChange(of: remitterAccountNumber) { _ in
        remitInfoSubject.send(())
      }
      .onChange(of: remitAmount) { _ in
        remitInfoSubject.send(())
      }
      .onReceive(remitInfoSubject) { _ in
        viewModel.verifyRemitInfo(info: .init(
          selectedGateway?.id,
          supportBankName,
          remitterName,
          remitterAccountNumber,
          remitAmount))
      }
    }
  }
}

extension OnlinePaymentView {
  // MARK: - Header

  struct Header: View {
    @EnvironmentObject private var viewModel: ViewModel

    private let selectedGateway: OnlinePaymentDataModel.Gateway?
    private let userGuideOnTap: () -> Void

    var inspection = Inspection<Self>()

    init(
      _ selectedGateway: OnlinePaymentDataModel.Gateway?,
      _ userGuideOnTap: @escaping () -> Void)
    {
      self.selectedGateway = selectedGateway
      self.userGuideOnTap = userGuideOnTap
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 18) {
        Text(viewModel.remitMethodName)
          .localized(weight: .semibold, size: 24, color: .whitePure)

        instruction
          .visibility(
            selectedGateway?.isInstructionDisplayed ?? false
              ? .visible
              : .gone)
          .id(OnlinePaymentView.Identifier.instructionLink.rawValue)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 30)
      .onInspected(inspection, self)
    }

    private var instruction: some View {
      HStack(spacing: 0) {
        Text(Localize.string("jinyidigital_instructions_click_here"))
          .localized(weight: .medium, size: 14, color: .redF20000)

        Image("iconChevronRightRed24")
      }
      .onTapGesture {
        userGuideOnTap()
      }
    }
  }

  // MARK: - Gateways

  struct Gateways: View {
    @EnvironmentObject private var viewModel: ViewModel

    @State private var cellHeight: CGFloat?

    @Binding private var selectedGateway: OnlinePaymentDataModel.Gateway?

    var inspection = Inspection<Self>()

    init(_ selectedGateway: Binding<OnlinePaymentDataModel.Gateway?>) {
      self._selectedGateway = selectedGateway
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text(Localize.string("deposit_select_method"))
          .localized(weight: .medium, size: 16, color: .gray9B9B9B)
          .padding(.horizontal, 30)

        VStack(spacing: 0) {
          Separator(color: .gray3C3E40)

          if viewModel.gateways.isEmpty {
            gatewayCell(id: "", name: "", hint: "", isLastCell: true)
          }
          else {
            ForEach(viewModel.gateways) { gateway in
              gatewayCell(
                id: gateway.id,
                name: gateway.name,
                hint: gateway.hint,
                isLastCell: gateway == viewModel.gateways.last)
            }
            .id(OnlinePaymentView.Identifier.gatewayCells.rawValue)
          }

          Separator(color: .gray3C3E40)
        }
        .backgroundColor(.gray131313)
        .onPreferenceChange(LargestCGFloat.self) { cellHeight in
          self.cellHeight = cellHeight
        }
        .onInspected(inspection, self)
      }
    }

    // MARK: - gatewayCell

    private func gatewayCell(
      id: String,
      name: String,
      hint: String,
      isLastCell: Bool)
      -> some View
    {
      VStack(spacing: 0) {
        HStack(spacing: 8) {
          HStack(spacing: 16) {
            Image("Default(32)")

            VStack(spacing: 4) {
              Text(name)
                .localized(weight: .medium, size: 14, color: .whitePure)
                .frame(maxWidth: .infinity, alignment: .leading)

              Text(hint)
                .localized(weight: .regular, size: 12, color: .gray9B9B9B)
                .frame(maxWidth: .infinity, alignment: .leading)
                .visibility(hint.isEmpty ? .gone : .visible)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: .infinity)
          }

          Image(
            selectedGateway == nil
              ? "iconSingleSelectionEmpty24"
              : id == selectedGateway!.id
              ? "iconSingleSelectionSelected24"
              : "iconSingleSelectionEmpty24")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 30)

        Separator(color: .gray3C3E40)
          .padding(.leading, 78)
          .visibility(isLastCell ? .gone : .visible)
      }
      .overlay(
        GeometryReader { proxy in
          Color.clear
            .preference(
              key: LargestCGFloat.self,
              value: proxy.size.height)
        })
      .frame(height: cellHeight)
      .contentShape(Rectangle())
      .onTapGesture {
        selectedGateway = viewModel.gateways
          .first(where: { $0.id == id })
      }
    }
  }

  // MARK: - RemittanceInfo

  struct RemittanceInfo: View {
    @EnvironmentObject var viewModel: ViewModel

    @Binding var supportBankName: String?
    @Binding var remitterName: String?
    @Binding var remitterAccountNumber: String?
    @Binding var remitAmount: String?

    private let selectedGateway: OnlinePaymentDataModel.Gateway?

    var inspection = Inspection<Self>()

    init(
      _ supportBankName: Binding<String?>,
      _ remitterName: Binding<String?>,
      _ remitterAccountNumber: Binding<String?>,
      _ remitAmount: Binding<String?>,
      _ selectedGateway: OnlinePaymentDataModel.Gateway?)
    {
      self._supportBankName = supportBankName
      self._remitterName = remitterName
      self._remitterAccountNumber = remitterAccountNumber
      self._remitAmount = remitAmount
      self.selectedGateway = selectedGateway
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        VStack(spacing: 0) {
          switch selectedGateway {
          case .none:
            normalForm(nil)
          case .some(let gateway):
            switch gateway.remitType {
            case .normal:
              normalForm(gateway)
                .id(OnlinePaymentView.Identifier.normalForm.rawValue)
            case .onlyamount:
              onlyAmountForm(gateway)
                .id(OnlinePaymentView.Identifier.onlyAmountForm.rawValue)
            case .frombank:
              fromBankForm(gateway)
            case .directto:
              directToForm(gateway)
            default:
              normalForm(gateway)
            }
          }
        }
        .zIndex(1)

        LimitSpacer(4)

        Text(Localize.string(
          "common_notify_currency_ratio"))
          .localized(weight: .medium, size: 14, color: .gray9B9B9B)
          .visibleLocale([.Vietnam()])
          .id(OnlinePaymentView.Identifier.vnCurrencyHint.rawValue)

        LimitSpacer(12)

        switch selectedGateway {
        case .none:
          EmptyView()
        case .some(let gateway):
          switch gateway.cashType {
          case .input(_, let isFloatAllowed):
            Text(Localize.string("deposit_float_hint"))
              .localized(weight: .medium, size: 14, color: .redD90101)
              .visibility(isFloatAllowed ? .visible : .gone)
              .id(OnlinePaymentView.Identifier.amountFloatHint.rawValue)
          case .option:
            EmptyView()
          }
        }
      }
      .padding(.horizontal, 30)
      .onInspected(inspection, self)
    }
  }

  // MARK: - RemittanceButton

  struct RemittanceButton: View {
    @EnvironmentObject var viewModel: ViewModel

    private let selectedGateway: OnlinePaymentDataModel.Gateway?
    private let supportBankName: String?
    private let remitterName: String?
    private let remitterAccountNumber: String?
    private let remitAmount: String?

    private let remitButtonOnSuccess: (_ url: String) -> Void

    var inspection = Inspection<Self>()

    init(
      _ selectedGateway: OnlinePaymentDataModel.Gateway?,
      _ supportBankName: String?,
      _ remitterName: String?,
      _ remitterAccountNumber: String?,
      _ remitAmount: String?,
      _ remitButtonOnSuccess: @escaping (_ url: String) -> Void)
    {
      self.selectedGateway = selectedGateway
      self.supportBankName = supportBankName
      self.remitterName = remitterName
      self.remitterAccountNumber = remitterAccountNumber
      self.remitAmount = remitAmount
      self.remitButtonOnSuccess = remitButtonOnSuccess
    }

    var body: some View {
      Button(
        action: {
          viewModel.submitRemittance(
            info: .init(
              selectedGateway?.id,
              supportBankName,
              remitterName,
              remitterAccountNumber,
              remitAmount))
          { url in
            remitButtonOnSuccess(url)
          }
        },
        label: {
          Text(Localize.string("deposit_offline_step1_button"))
        })
        .buttonStyle(.confirmRed)
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .backgroundColor(.black131313)
        .disabled(viewModel.submitButtonDisable)
        .id(OnlinePaymentView.Identifier.remittanceButton.rawValue)
        .onInspected(inspection, self)
    }
  }
}

// Mark onViewDidLoad to view preview.

struct OnlinePaymentView_Previews: PreviewProvider {
  class FakeViewModel:
    OnlinePaymentViewModelProtocol &
    ObservableObject
  {
    @Published private(set) var remitMethodName = ""
    @Published private(set) var gateways: [OnlinePaymentDataModel.Gateway] = [
      .init(
        id: "1",
        name: "normal",
        hint: "温馨提示：请您在使用该充值渠道前，先行下载京东商城APP。",
        remitType: .normal,
        remitBanks: [],
        cashType: .input(limitation: ("50", "100"), isFloatAllowed: false), isAccountNumberDenied: false,
        isInstructionDisplayed: true),
      .init(
        id: "2",
        name: "normal (deniedAccountNumber)",
        hint: "",
        remitType: .normal,
        remitBanks: [],
        cashType: .input(limitation: ("50", "100"), isFloatAllowed: true), isAccountNumberDenied: true,
        isInstructionDisplayed: false),
      .init(
        id: "3",
        name: "onlyAmount (input)",
        hint: "",
        remitType: .onlyamount,
        remitBanks: [],
        cashType: .input(limitation: ("50", "100"), isFloatAllowed: true),
        isAccountNumberDenied: false, isInstructionDisplayed: false),
      .init(
        id: "4",
        name: "onlyAmount (optional)",
        hint: "",
        remitType: .onlyamount,
        remitBanks: [],
        cashType: .option(amountList: ["50", "100"]),
        isAccountNumberDenied: false, isInstructionDisplayed: false),
      .init(
        id: "5",
        name: "fromBank",
        hint: "",
        remitType: .frombank,
        remitBanks: [],
        cashType: .input(limitation: ("50", "100"), isFloatAllowed: true),
        isAccountNumberDenied: false, isInstructionDisplayed: false),
      .init(
        id: "6",
        name: "directTo",
        hint: "",
        remitType: .directto,
        remitBanks: [],
        cashType: .option(amountList: ["50", "100"]),
        isAccountNumberDenied: false, isInstructionDisplayed: false)
    ]

    @Published private(set) var remitterName = "TestRemitter"

    @Published private(set) var remitInfoErrorMessage: OnlinePaymentDataModel.RemittanceInfoError = .empty
    @Published private(set) var submitButtonDisable = true

    func setupData(onlineDTO _: PaymentsDTO.Online) { }

    func verifyRemitInfo(info _: OnlinePaymentDataModel.RemittanceInfo) { }

    func submitRemittance(
      info _: OnlinePaymentDataModel.RemittanceInfo,
      remitButtonOnSuccess _: @escaping (_ url: String) -> Void) { }
  }

  static var previews: some View {
    OnlinePaymentView(
      viewModel: FakeViewModel(),
      onlinePaymentDTO: nil,
      userGuideOnTap: {
        // do nothing
      },
      remitButtonOnSuccess: { _ in
        // do nothing
      })
      .environment(\.playerLocale, .Vietnam())
  }
}
