import sharedbu
import SwiftUI

extension CasinoBetDetailView {
  enum Identifier: String {
    case roundIDCell
    case title
    case content
  }
}

struct CasinoBetDetailView<ViewModel>: View
  where ViewModel: ICasinoBetDetailViewModel & ObservableObject
{
  @StateObject private var viewModel: ViewModel
  
  @State private var viewDidLoad = false
  
  private let wagerID: String
  
  init(
    viewModel: ViewModel,
    wagerID: String)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.wagerID = wagerID
  }
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(spacing: 0) {
          Separator()
          
          if let betDetail = viewModel.betDetail {
            WagerIDCell(betDetail)
            
            RoundIDCell(betDetail)
            
            Cell(
              titleKey: "product_bet_content",
              content: betDetail.selection)
            
            Cell(
              titleKey: "product_bet_time",
              content: betDetail.betTime.toDateTimeWithDayOfWeekString(by: viewModel.getSupportLocale()))
            
            Cell(
              titleKey: "product_bet_amount",
              content: betDetail.stakes.description() +
                "\n" +
                Localize.string("product_prededuct") +
                " " +
                betDetail.prededuct.description())
                
            WinLossCell(betDetail)
            
            GameResultCell(betDetail)
          }
          
          Separator()
        }
      }
    }
    .onPageLoading(viewModel.betDetail == nil)
    .backgroundColor(.greyScaleDefault, ignoresSafeArea: .all)
    .environmentObject(viewModel)
    .onViewDidLoad {
      viewModel.setup(with: wagerID)
    }
  }
}

extension CasinoBetDetailView {
  // MARK: - Cell
  
  struct Cell: View {
    private let titleKey: String
    private let content: String
    private let isLastCell: Bool
 
    var inspection = Inspection<Self>()
    
    init(titleKey: String, content: String, isLastCell: Bool = false) {
      self.titleKey = titleKey
      self.content = content
      self.isLastCell = isLastCell
    }
    
    var body: some View {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 2) {
          Text(key: titleKey)
            .localized(weight: .regular, size: 12, color: .textPrimary)
            .id(CasinoBetDetailView.Identifier.title.rawValue)
            
          Text(content)
            .localized(weight: .regular, size: 16, color: .greyScaleWhite)
            .id(CasinoBetDetailView.Identifier.content.rawValue)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        
        Separator()
          .visibility(isLastCell ? .gone : .visible)
      }
      .padding(.horizontal, 30)
      .onInspected(inspection, self)
    }
  }
  
  // MARK: - WagerIDCell
  
  struct WagerIDCell: View {
    private let betDetail: CasinoDTO.BetDetail
    
    init(_ betDetail: CasinoDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 2) {
          Text(key: "product_bet_id")
            .localized(weight: .regular, size: 12, color: .textPrimary)
            
          Text(betDetail.id)
            .localized(weight: .regular, size: 16, color: .greyScaleWhite)
          
          if !betDetail.otherId.isEmpty {
            Text(betDetail.otherId)
              .localized(weight: .regular, size: 14, color: .textPrimary)
          }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        
        Separator()
      }
      .padding(.horizontal, 30)
    }
  }
  
  // MARK: - RoundIDCell
  
  struct RoundIDCell: View {
    private let betDetail: CasinoDTO.BetDetail
    
    var inspection = Inspection<Self>()
    
    init(_ betDetail: CasinoDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
      VStack {
        if let roundID = betDetail.roundId {
          CasinoBetDetailView.Cell(
            titleKey: "product_game_name_id",
            content: betDetail.gameName + "(\(roundID))")
        }
        else {
          CasinoBetDetailView.Cell(
            titleKey: "product_game_name",
            content: betDetail.gameName)
        }
      }
      .id(CasinoBetDetailView.Identifier.roundIDCell.rawValue)
      .onInspected(inspection, self)
    }
  }
  
  // MARK: - WinLossCell
  
  struct WinLossCell: View {
    private let betDetail: CasinoDTO.BetDetail
    
    init(_ betDetail: CasinoDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 2) {
          Text(key: "product_bet_win_lose")
            .localized(weight: .regular, size: 12, color: .textPrimary)
          
          let winLose = betDetail.winLose
          
          switch winLose.status {
          case .win:
            Text(key: "product_winning_amount", winLose.amount.formatString())
              .localized(weight: .regular, size: 16, color: .statusSuccess)
          case .lose:
            Text(key: "product_losing_amount", winLose.amount.formatString())
              .localized(weight: .regular, size: 16, color: .greyScaleWhite)
          }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        
        Separator()
      }
      .padding(.horizontal, 30)
    }
  }
  
  // MARK: - GameResultCell
  
  struct GameResultCell: View {
    private let betDetail: CasinoDTO.BetDetail
    
    init(_ betDetail: CasinoDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
      switch betDetail.status {
      case .canceled,
           .void:
        cancelView
        
      case .bet,
           .settled:
        resultView
      }
    }
    
    private var cancelView: some View {
      CasinoBetDetailView.Cell(
        titleKey: "product_bet_result",
        content: Localize.string("common_cancel"),
        isLastCell: true)
    }
    
    private var resultView: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text(key: "product_bet_result")
          .localized(weight: .regular, size: 12, color: .textPrimary)
        
        BetDetailResultView(result: betDetail.gameResult)
      }
      .padding(.horizontal, 30)
      .padding(.top, 12)
      .padding(.bottom, 30)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

// MARK: - Preview

struct CasinoBetDetailView_Previews: PreviewProvider {
  class FakeViewModel:
    ICasinoBetDetailViewModel &
    ObservableObject
  {
    @Published var betDetail: CasinoDTO.BetDetail? = .init(
      id: "12345678901234567890123456789012",
      otherId: "12345678901234567890123456789012",
      roundId: "GC20201005050250",
      betTime: Instant.companion.fromEpochSeconds(epochSeconds: Int64(0), nanosecondAdjustment: Int32(0)),
      selection: "大/小:大",
      gameName: "轮盘",
      gameResult: .init(
        displayType: .verticalPokerSet,
        cards: stubPokerGroup,
        dices: stubDices,
        roulette: stubRoulette,
        chineseDice: stubChineseDices,
        fanTan: stubFanTan,
        colorPlates: stubColorPlates),
      stakes: FiatFactory.shared.create(supportLocale: .China(), amount: "50.00"),
      prededuct: FiatFactory.shared.create(supportLocale: .China(), amount: "50.00"),
      winLose: .init(status: .win, amount: FiatFactory.shared.create(supportLocale: .China(), amount: "500.00")),
      status: .settled)
    
    static let stubPokerGroup: [PokerGroup] = [
      .init(title: "banker", cards: [
        .init(title: "", cards: [
          Poker.Standard(pokerSuits: .heart, pokerNumber: .king),
          Poker.Standard(pokerSuits: .clover, pokerNumber: .three),
          Poker.Standard(pokerSuits: .clover, pokerNumber: .seven)
        ])
      ]),
      .init(title: "Player 1", cards: [
        .init(title: "", cards: [
          Poker.Standard(pokerSuits: .spades, pokerNumber: .king),
          Poker.Standard(pokerSuits: .diamond, pokerNumber: .six),
          Poker.Standard(pokerSuits: .heart, pokerNumber: .ten)
        ])
      ]),
      .init(title: "Player 2", cards: [
        .init(title: "No Player", cards: [])
      ]),
      .init(title: "Player 3", cards: [
        .init(title: "Split", cards: [
          Poker.Standard(pokerSuits: .heart, pokerNumber: .three),
          Poker.Standard(pokerSuits: .heart, pokerNumber: .five),
          Poker.Standard(pokerSuits: .spades, pokerNumber: .king)
        ]),
        .init(title: "Split", cards: [
          Poker.Standard(pokerSuits: .spades, pokerNumber: .three),
          Poker.Standard(pokerSuits: .spades, pokerNumber: .jack),
        ])
      ]),
    ]
    static let stubDices: [DiceNumber] = [.two, .three, .six]
    static let stubRoulette: KotlinInt = .init(int: 10)
    static let stubChineseDices: [ChineseDice] = [.coin, .shrimp, .chicken]
    static let stubFanTan: KotlinInt = .init(int: 3)
    static let stubColorPlates: [Plate] = [.white, .red, .red, .white]
    
    func setup(with _: String) { }
    
    func getSupportLocale() -> SupportLocale {
      .China()
    }
  }
  
  static var previews: some View {
    CasinoBetDetailView(viewModel: FakeViewModel(), wagerID: "")
  }
}
