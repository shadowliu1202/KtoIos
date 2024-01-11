import sharedbu
import SwiftUI

extension NumberGameMyBetDetailContent {
  enum TestTag: String {
    case subDescription
    case ballGameResult
    case prizeGameResult
  }
}

struct NumberGameMyBetDetailContent: View {
  let myBetDetail: NumberGameBetDetail
  let page: Int
  let supportLocale: SupportLocale
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer(backgroundColor: .greyScaleDefault) {
        Separator()
        
        VStack(alignment: .leading, spacing: 0) {
          CellWithSeparator(
            titleLocalizeKey: "product_bet_id",
            description: myBetDetail.displayId,
            subDescription: myBetDetail.traceId)
          
          CellWithSeparator(
            titleLocalizeKey: "product_number_game_name_id",
            description: myBetDetail.gameName + " " + myBetDetail.matchMethod)
          
          CellWithSeparator(
            titleLocalizeKey: "product_bet_content",
            description: myBetDetail.betContent.joined(separator: "\n"))
          
          CellWithSeparator(
            titleLocalizeKey: "product_bet_time",
            description: toString(myBetDetail.betTime))
        
          CellWithSeparator(
            titleLocalizeKey: "product_bet_amount",
            description: myBetDetail.stakes.description())
          
          CellWithSeparator(
            titleLocalizeKey: "common_status",
            description: myBetDetail.status.LocalizeString,
            descriptionColor: isWinLossPositive() ? .statusSuccess : .greyScaleWhite,
            isLast: myBetDetail.result == NumberGameBetDetail.GameResultEmpty())
          
          if myBetDetail.result != NumberGameBetDetail.GameResultEmpty() {
            GameResultCell(result: myBetDetail.result)
          }
        }
        .padding(.horizontal, 30)
        
        Separator()
      }
    }
  }
  
  private func toString(_ localDateTime: LocalDateTime) -> String {
    let dateFormatter = Theme.shared.getBetTimeWeekdayFormat(by: supportLocale)
    return dateFormatter.string(from: localDateTime.convertToDate())
  }
  
  private func isWinLossPositive() -> Bool {
    guard let status = myBetDetail.status as? NumberGameBetDetail.BetStatusSettledWinLose
    else { return false }
    
    return status.winLoss.isPositive
  }
}

extension NumberGameMyBetDetailContent {
  // MARK: - CellWithSeparator
  
  struct CellWithSeparator: View {
    private let titleLocalizeKey: String
    private let description: String
    private let descriptionColor: UIColor?
    private let subDescription: String?
    private let isLast: Bool
    
    init(
      titleLocalizeKey: String,
      description: String,
      descriptionColor: UIColor? = nil,
      subDescription: String? = nil,
      isLast: Bool = false)
    {
      self.titleLocalizeKey = titleLocalizeKey
      self.description = description
      self.subDescription = subDescription
      self.descriptionColor = descriptionColor
      self.isLast = isLast
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: 2) {
        NumberGameMyBetDetailContent.Cell(
          titleLocalizeKey: titleLocalizeKey,
          description: description,
          descriptionColor: descriptionColor)
        
        if let subDescription, !subDescription.isEmpty {
          Text(subDescription)
            .localized(weight: .regular, size: 14, color: .textPrimary)
            .id(NumberGameMyBetDetailContent.TestTag.subDescription.rawValue)
        }
      }
      .padding(.vertical, 12)
      
      if !isLast {
        Separator()
      }
    }
  }
  
  // MARK: - Cell
  
  struct Cell: View {
    private let titleLocalizeKey: String
    private let description: String
    private let descriptionColor: UIColor?
    
    init(
      titleLocalizeKey: String,
      description: String,
      descriptionColor: UIColor? = nil)
    {
      self.titleLocalizeKey = titleLocalizeKey
      self.description = description
      self.descriptionColor = descriptionColor
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: 2) {
        Text(key: titleLocalizeKey)
          .localized(weight: .regular, size: 12, color: .textPrimary)
        
        Text(description)
          .localized(weight: .regular, size: 16, color: descriptionColor ?? .greyScaleWhite)
      }
    }
  }
  
  // MARK: - GameResultCell
  
  struct GameResultCell: View {
    let result: NumberGameBetDetail.GameResult
    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text(key: "product_draw_result")
          .localized(weight: .regular, size: 12, color: .textPrimary)
        
        switch result {
        case _ as NumberGameBetDetail.GameResultEmpty:
          EmptyView()
          
        case let result as NumberGameBetDetail.GameResultBall:
          NumberGameMyBetDetailContent.BallResultCell(numbers: result.balls.map { $0.description })
            .frame(maxWidth: .infinity)
            .id(NumberGameMyBetDetailContent.TestTag.ballGameResult.rawValue)
          
        case let result as NumberGameBetDetail.GameResultPrize:
          NumberGameMyBetDetailContent.PrizeResultCell(prizes: result.prizes)
            .id(NumberGameMyBetDetailContent.TestTag.prizeGameResult.rawValue)
          
        default:
          fatalError("should not reach here.")
        }
      }
      .padding(.top, 12)
      .padding(.bottom, 30)
    }
  }
  
  // MARK: - BallResultCell
  
  struct BallResultCell: View {
    let numbers: [String]
    
    var body: some View {
      HStack(spacing: 10) {
        ForEach(numbers, id: \.self) {
          ball(number: $0)
        }
      }
    }
    
    func ball(number: String) -> some View {
      Circle()
        .fill(Color.from(.primaryForLight))
        .overlay(
          Circle()
            .strokeBorder(Color.from(.greyScaleChatWindow), lineWidth: 2))
        .frame(width: 40, height: 40)
        .overlay(
          Text(number)
            .localized(weight: .semibold, size: 14, color: .greyScaleWhite))
    }
  }
  
  // MARK: - PrizeResultCell
  
  struct PrizeResultCell: View {
    let prizes: [NumberGameBetDetail.GameResultPrizeItem]
    
    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(prizes.indices, id: \.self) { index in
          let prize = prizes[index]
          NumberGameMyBetDetailContent.Cell(titleLocalizeKey: prize.title, description: prize.content)
        }
      }
    }
  }
}

struct NumberGameMyBetDetailContent_Previews: PreviewProvider {
  static var previews: some View {
    NumberGameMyBetDetailContent(
      myBetDetail: NumberGameBetDetail(
        displayId: "12345678901234567890123456789012",
        traceId: "12345678901234567890123456789012",
        gameName: "重庆时时彩",
        matchMethod: "(20200803-045)",
        betContent: ["中三直选跨度 [中三_直选跨度]", "1,2,3,4,5"],
        betTime: Date().toLocalDateTime(.current),
        stakes: "50".toAccountCurrency(),
        status: NumberGameBetDetail.BetStatusSettledWinLose(winLoss: "50".toAccountCurrency()),
        resultType: .prize,
        _result: """
        {
          "Giải ĐB": "00057",
          "Giải nhất": "60930",
          "Giải nhì": "58590-31347",
          "Giải ba": "41010-41582-63910-65482-51356-13561-37591",
          "Giải tư": "5826",
          "Giải năm": "7130-3457-2179",
          "Giải sáu": "863",
          "Giải bảy": "91",
          "Giải tám": "02135",
          "Sequence": "[\\\"Giải ĐB\\\",\\\"Giải nhất\\\",\\\"Giải nhì\\\",\\\"Giải ba\\\",\\\"Giải tư\\\",\\\"Giải năm\\\",\\\"Giải sáu\\\",\\\"Giải bảy\\\",\\\"Giải tám\\\"]"
        }
        """),
      page: 1,
      supportLocale: .Vietnam())
  }
}
