import sharedbu
import SwiftUI

extension WithdrawalMainView {
  enum Identifier: String {
    case dailyAmountLimit
    case dailyCountLimit
    case cryptoRequirementAmount
    case cryptoRequirementNone
    case methods
    case methodCrypto
    case methodFiat
  }
}

struct WithdrawalMainView<ViewModel>: View
  where ViewModel:
  WithdrawalMainViewModelProtocol &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel

  private let cryptoTurnOverOnClick: () -> Void
  private let noneCryptoTurnOverOnClick: () -> Void

  private let withdrawalOnAllowedFiat: () -> Void
  private let withdrawalOnDisAllowedFiat: () -> Void

  private let withdrawalOnAllowedCrypto: () -> Void
  private let withdrawalOnDisAllowedCrypto: () -> Void

  private let showAllRecordsOnTap: () -> Void
  private let withdrawalRecordOnTap: (_ id: String, _ type: WithdrawalDto.LogCurrencyType) -> Void

  init(
    viewModel: ViewModel,
    cryptoTurnOverOnClick: @escaping () -> Void = { },
    noneCryptoTurnOverOnClick: @escaping () -> Void = { },
    withdrawalOnAllowedFiat: @escaping () -> Void = { },
    withdrawalOnDisAllowedFiat: @escaping () -> Void = { },
    withdrawalOnAllowedCrypto: @escaping () -> Void = { },
    withdrawalOnDisAllowedCrypto: @escaping () -> Void = { },
    showAllRecordsOnTap: @escaping () -> Void = { },
    withdrawalRecordOnTap: @escaping (_ id: String, _ type: WithdrawalDto.LogCurrencyType) -> Void = { _, _ in })
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.cryptoTurnOverOnClick = cryptoTurnOverOnClick
    self.noneCryptoTurnOverOnClick = noneCryptoTurnOverOnClick
    self.withdrawalOnAllowedFiat = withdrawalOnAllowedFiat
    self.withdrawalOnDisAllowedFiat = withdrawalOnDisAllowedFiat
    self.withdrawalOnAllowedCrypto = withdrawalOnAllowedCrypto
    self.withdrawalOnDisAllowedCrypto = withdrawalOnDisAllowedCrypto
    self.showAllRecordsOnTap = showAllRecordsOnTap
    self.withdrawalRecordOnTap = withdrawalRecordOnTap
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(spacing: 0) {
          Instruction(cryptoTurnOverOnClick, noneCryptoTurnOverOnClick)

          LimitSpacer(21)

          Methods(
            withdrawalOnAllowedFiat,
            withdrawalOnDisAllowedFiat,
            withdrawalOnAllowedCrypto,
            withdrawalOnDisAllowedCrypto)

          LimitSpacer(25)

          RecentRecords(showAllRecordsOnTap, withdrawalRecordOnTap)
        }
      }
    }
    .onPageLoading(viewModel.instruction == nil || viewModel.recentRecords == nil)
    .pageBackgroundColor(.greyScaleDefault)
    .environmentObject(viewModel)
    .onAppear {
      viewModel.setupData()
    }
  }
}

extension WithdrawalMainView {
  // MARK: - Instruction

  struct Instruction: View {
    @EnvironmentObject private var viewModel: ViewModel

    private let cryptoTurnOverOnClick: () -> Void
    private let noneCryptoTurnOverOnClick: () -> Void

    var inspection = Inspection<Self>()

    init(
      _ cryptoTurnOverOnClick: @escaping () -> Void = { },
      _ noneCryptoTurnOverOnClick: @escaping () -> Void = { })
    {
      self.cryptoTurnOverOnClick = cryptoTurnOverOnClick
      self.noneCryptoTurnOverOnClick = noneCryptoTurnOverOnClick
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(Localize.string(
          "withdrawal_daily_limit_widthrawal_amount",
          viewModel.instruction?.dailyAmountLimit ?? ""))
          .localized(weight: .medium, size: 14, color: .textPrimary)
          .id(WithdrawalMainView.Identifier.dailyAmountLimit.rawValue)

        Text(Localize.string(
          "withdrawal_daily_limit_widthrawal_times",
          viewModel.instruction?.dailyMaxCount ?? ""))
          .localized(weight: .medium, size: 14, color: .textPrimary)
          .id(WithdrawalMainView.Identifier.dailyCountLimit.rawValue)

        HStack(spacing: 0) {
          Text(Localize.string("withdrawal_turnover_requirement"))

          if let turnoverRequirement = viewModel.instruction?.turnoverRequirement {
            Text(Localize.string("common_requirement", turnoverRequirement))
          }
          else {
            Text(Localize.string("common_none"))
          }
        }
        .localized(weight: .medium, size: 14, color: .textPrimary)

        if let (amount, _) = viewModel.instruction?.cryptoWithdrawalRequirement {
          HStack(alignment: .center, spacing: 0) {
            Text(Localize.string("cps_crpyto_withdrawal_requirement"))
              .foregroundColor(.from(.textPrimary)) +
              Text(Localize.string("common_requirement", amount))
              .foregroundColor(.from(.primaryDefault)) +
              Text(" \(Image(systemName: "chevron.right"))")
              .foregroundColor(
                .from(.primaryDefault))
          }
          .contentShape(Rectangle())
          .onTapGesture {
            cryptoTurnOverOnClick()
          }
          .localized(weight: .medium, size: 14)
          .id(WithdrawalMainView.Identifier.cryptoRequirementAmount.rawValue)
        }
        else {
          HStack(spacing: 8) {
            HStack(spacing: 0) {
              Text(Localize.string("cps_crpyto_withdrawal_requirement"))
                .localized(weight: .medium, size: 14, color: .textPrimary)

              Text(Localize.string("common_none"))
                .localized(weight: .medium, size: 14, color: .textPrimary)
                .id(WithdrawalMainView.Identifier.cryptoRequirementNone.rawValue)
            }

            Image("Tips")
              .onTapGesture {
                noneCryptoTurnOverOnClick()
              }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 30)
      .onInspected(inspection, self)
    }
  }

  // MARK: - Methods

  struct Methods: View {
    @EnvironmentObject private var viewModel: ViewModel

    private let withdrawalOnAllowedFiat: () -> Void
    private let withdrawalOnDisAllowedFiat: () -> Void

    private let withdrawalOnAllowedCrypto: () -> Void
    private let withdrawalOnDisAllowedCrypto: () -> Void

    var inspection = Inspection<Self>()

    init(
      _ withdrawalOnAllowedFiat: @escaping () -> Void = { },
      _ withdrawalOnDisAllowedFiat: @escaping () -> Void = { },
      _ withdrawalOnAllowedCrypto: @escaping () -> Void = { },
      _ withdrawalOnDisAllowedCrypto: @escaping () -> Void = { })
    {
      self.withdrawalOnAllowedFiat = withdrawalOnAllowedFiat
      self.withdrawalOnDisAllowedFiat = withdrawalOnDisAllowedFiat
      self.withdrawalOnAllowedCrypto = withdrawalOnAllowedCrypto
      self.withdrawalOnDisAllowedCrypto = withdrawalOnDisAllowedCrypto
    }

    var body: some View {
      VStack(spacing: 0) {
        Separator()

        ForEach(viewModel.methods) {
          let isLast = viewModel.methods.last == $0
          switch $0 {
          case .fiat:
            methodCell(
              iconName: "IconPayWithdrawal",
              methodName: Localize.string("withdrawal_cash_withdrawal"),
              isLastCell: isLast,
              isDisable: !viewModel.enableWithdrawal)
              .onTapGesture {
                guard let allowedWithdrawal = viewModel.allowedWithdrawalFiat
                else { return }

                if allowedWithdrawal {
                  withdrawalOnAllowedFiat()
                }
                else {
                  withdrawalOnDisAllowedFiat()
                }
              }
              .id(WithdrawalMainView.Identifier.methodFiat.rawValue)
            
          case .crypto:
            methodCell(
              iconName: "IconPayCrypto",
              methodName: Localize.string("cps_crpyto_withdrawal"),
              isLastCell: isLast,
              isDisable: !viewModel.enableWithdrawal)
              .onTapGesture {
                guard let allowedWithdrawal = viewModel.allowedWithdrawalCrypto
                else { return }

                if allowedWithdrawal {
                  withdrawalOnAllowedCrypto()
                }
                else {
                  withdrawalOnDisAllowedCrypto()
                }
              }
              .id(WithdrawalMainView.Identifier.methodCrypto.rawValue)
          }
        }
        
        Separator()
      }
      .id(WithdrawalMainView.Identifier.methods.rawValue)
      .disabled(!viewModel.enableWithdrawal)
      .onInspected(inspection, self)
    }

    func methodCell(
      iconName: String,
      methodName: String,
      isLastCell: Bool = false,
      isDisable: Bool)
      -> some View
    {
      HStack(spacing: 8) {
        HStack(spacing: 16) {
          Image(iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)

          Text(methodName)
            .localized(weight: .medium, size: 14, color: .greyScaleWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Image("iconChevronRight16")
      }
      .opacity(isDisable ? 0.5 : 1)
      .padding(.vertical, 12)
      .padding(.leading, 30)
      .padding(.trailing, 16)
      .backgroundColor(.greyScaleList)
      .overlay(
        Separator()
          .padding(.leading, 78)
          .visibility(isLastCell ? .gone : .visible),
        alignment: .bottom)
      .contentShape(Rectangle())
    }
  }

  // MARK: - RecentRecords

  struct RecentRecords: View {
    @EnvironmentObject private var viewModel: ViewModel

    private let showAllRecordsOnTap: () -> Void
    private let recordOnTap: (_ id: String, _ type: WithdrawalDto.LogCurrencyType) -> Void

    init(
      _ showAllRecordsOnTap: @escaping () -> Void = { },
      _ recordOnTap: @escaping (_ id: String, _ type: WithdrawalDto.LogCurrencyType) -> Void = { _, _ in })
    {
      self.showAllRecordsOnTap = showAllRecordsOnTap
      self.recordOnTap = recordOnTap
    }

    var body: some View {
      VStack(spacing: 16) {
        header

        if let recentRecords = viewModel.recentRecords {
          if recentRecords.isEmpty {
            noRecordView
          }
          else {
            recordCells(recentRecords)
          }
        }
        else {
          EmptyView()
        }
      }
    }

    var header: some View {
      HStack(alignment: .bottom, spacing: 0) {
        Text(Localize.string("withdrawal_log"))
          .localized(weight: .medium, size: 18, color: .textPrimary)

        Spacer()

        Text(Localize.string("common_show_all"))
          .localized(weight: .medium, size: 14, color: .primaryDefault)
          .onTapGesture {
            showAllRecordsOnTap()
          }
          .visibility(
            viewModel.recentRecords?.isEmpty == false
              ? .visible
              : .gone)
      }
      .padding(.horizontal, 30)
    }

    func recordCells(_ recentRecords: [WithdrawalMainViewDataModel.Record]) -> some View {
      VStack(spacing: 0) {
        ForEach(recentRecords) { record in
          RecentRecordRow(
            date: record.date,
            statusTitle: record.status.title,
            statusColor: record.status.color,
            id: record.id,
            amount: record.amount,
            isLastCell: record == recentRecords.last)
            .onTapGesture {
              recordOnTap(record.id, record.currencyType)
            }
        }
      }
      .overlay(
        Separator(),
        alignment: .top)
      .overlay(
        Separator(),
        alignment: .bottom)
    }

    var noRecordView: some View {
      Text(Localize.string("withdrawal_no_records"))
        .localized(weight: .regular, size: 14, color: .greyScaleWhite)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }
  }
}

struct WithdrawalMainView_Previews: PreviewProvider {
  class FakeViewModel:
    WithdrawalMainViewModelProtocol,
    ObservableObject
  {
    @Published var instruction: WithdrawalMainViewDataModel.Instruction? = .init(
      dailyAmountLimit: "100,000",
      dailyMaxCount: "5",
      turnoverRequirement: "仍需20,00",
      cryptoWithdrawalRequirement: ("1,003 ", "$"))
    
    @Published var methods: [WithdrawalDto.Method] = [.fiat, .crypto]

    @Published var recentRecords: [WithdrawalMainViewDataModel.Record]? = [
      .init(
        id: "PWCMQ1338287752",
        currencyType: .fiat,
        date: "2019/10/09 22:43:08",
        status: .init(
          title: "需上传交易资讯",
          color: .alert),
        amount: "100.05"),
      .init(
        id: "PWCMQ1338287753",
        currencyType: .fiat,
        date: "2019/10/09 22:43:08",
        status: .init(
          title: "成功",
          color: .textPrimary),
        amount: "100.05"),
      .init(
        id: "PWCMQ1338287754",
        currencyType: .crypto,
        date: "2019/10/09 22:43:08",
        status: .init(
          title: "失败",
          color: .textPrimary),
        amount: "100.05"),
      .init(
        id: "PWCMQ1338287755",
        currencyType: .crypto,
        date: "2019/10/09 22:43:08",
        status: .init(
          title: "取消",
          color: .textPrimary),
        amount: "100.05"),
      .init(
        id: "PWCMQ1338287756",
        currencyType: .fiat,
        date: "2019/10/09 22:43:08",
        status: .init(
          title: "处理中",
          color: .textPrimary),
        amount: "100.05"),
    ]

    @Published var enableWithdrawal = false
    @Published var allowedWithdrawalFiat: Bool?
    @Published var allowedWithdrawalCrypto: Bool?

    func setupData() { }
  }

  static var previews: some View {
    WithdrawalMainView(viewModel: FakeViewModel())
  }
}
