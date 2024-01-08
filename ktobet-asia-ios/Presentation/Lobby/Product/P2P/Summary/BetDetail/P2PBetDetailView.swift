import sharedbu
import SwiftUI

struct P2PBetDetailView<ViewModel>: View
  where ViewModel: IP2PBetDetailViewModel & ObservableObject
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
            cell(
              titleKey: "product_bet_id",
              content: betDetail.identity)
            
            cell(
              titleKey: "product_game_name",
              content: betDetail.gameName)
            
            cell(
              titleKey: "product_bet_content",
              content: betDetail.selections)
            
            cell(
              titleKey: "product_bet_time",
              content: betDetail.betTime.toDateTimeWithDayOfWeekString(by: viewModel.getSupportLocale()))
            
            cell(
              titleKey: "product_bet_amount",
              content: betDetail.stakes.description())
            
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
  
  private func cell(titleKey: String, content: String) -> some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        Text(key: titleKey)
          .localized(weight: .regular, size: 12, color: .textPrimary)
          
        Text(content)
          .localized(weight: .regular, size: 16, color: .greyScaleWhite)
      }
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      
      Separator()
    }
    .padding(.horizontal, 30)
  }
}

extension P2PBetDetailView {
  // MARK: - WinLossCell
  
  struct WinLossCell: View {
    private let betDetail: P2PDTO.BetDetail
    
    init(_ betDetail: P2PDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 2) {
          Text(key: "product_bet_win_lose")
            .localized(weight: .regular, size: 12, color: .textPrimary)
          
          let winLoss = betDetail.winLose
          
          switch winLoss.status {
          case .win:
            Text(key: "product_winning_amount", winLoss.amount.formatString())
              .localized(weight: .regular, size: 16, color: .statusSuccess)
          case .lose:
            Text(key: "product_losing_amount", winLoss.amount.formatString())
              .localized(weight: .regular, size: 16, color: .greyScaleWhite)
          default:
            fatalError("should not reach here.")
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
    private let betDetail: P2PDTO.BetDetail
    
    init(_ betDetail: P2PDTO.BetDetail) {
      self.betDetail = betDetail
    }
    
    var body: some View {
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

struct P2PBetDetailView_Previews: PreviewProvider {
  class FakeViewModel:
    IP2PBetDetailViewModel &
    ObservableObject
  {
    @Published var betDetail: P2PDTO.BetDetail? = .init(
      identity: "50-1686553970-1275411025-1",
      stakes: FiatFactory.shared.create(supportLocale: .China(), amount_: "50.00"),
      gameName: "Four Cards Bull",
      betTime: Instant.companion.fromEpochSeconds(epochSeconds: 0, nanosecondAdjustment: 0),
      selections: "Player 1\nBet x5",
      winLose: .init(status: .win, amount: FiatFactory.shared.create(supportLocale: .China(), amount_: "500.00")),
      gameResult: .init(
        displayType: .colorplate,
        cards: stubPokerGroup,
        dices: stubDices,
        roulette: stubRoulette,
        chineseDice: stubChineseDices,
        fanTan: stubFanTan,
        colorPlates: stubColorPlates))
    
    static let stubPokerGroup: [PokerGroup] = [
      .init(title: "banker", cards: [
        .init(title: "", cards: [
          PokerStandard(pokerSuits: .heart, pokerNumber: .king),
          PokerStandard(pokerSuits: .clover, pokerNumber: .three),
          PokerStandard(pokerSuits: .clover, pokerNumber: .seven)
        ])
      ]),
      .init(title: "Player 1", cards: [
        .init(title: "", cards: [
          PokerStandard(pokerSuits: .spades, pokerNumber: .king),
          PokerStandard(pokerSuits: .diamond, pokerNumber: .six),
          PokerStandard(pokerSuits: .heart, pokerNumber: .ten)
        ])
      ]),
      .init(title: "Player 2", cards: [
        .init(title: "No Player", cards: [])
      ]),
      .init(title: "Player 3", cards: [
        .init(title: "Split", cards: [
          PokerStandard(pokerSuits: .heart, pokerNumber: .three),
          PokerStandard(pokerSuits: .heart, pokerNumber: .five),
          PokerStandard(pokerSuits: .spades, pokerNumber: .king)
        ]),
        .init(title: "Split", cards: [
          PokerStandard(pokerSuits: .spades, pokerNumber: .three),
          PokerStandard(pokerSuits: .spades, pokerNumber: .jack),
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
    P2PBetDetailView(viewModel: FakeViewModel(), wagerID: "")
  }
}
