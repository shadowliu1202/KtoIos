import Foundation
import sharedbu

struct ResponseData<T: Codable>: Codable {
  var statusCode: String
  var errorMsg: String
  var node: String?
  var data: T?
}

struct NonNullResponseData<T: Codable>: Codable {
  var statusCode: String
  var errorMsg: String?
  var node: String?
  var data: T
}

struct ResponseDataList<T: Codable>: Codable {
  var statusCode: String
  var errorMsg: String
  var node: String?
  var data: [T]
}

struct ResponseDataMap<T: Codable>: Codable {
  var statusCode: String
  var errorMsg: String
  var node: String?
  var data: [String: T]
}

struct ResponseDataPage<T: Codable>: Codable {
  var data: [T]
  var totalCount: Int
}

struct PayloadPage<T: Codable>: Codable {
  var payload: [T]
  var totalCount: Int
}

struct PromotionHistoryBean: Codable {
  var payload: [PromotionPayload]
  var summary: Double
  var totalCount: Int

  func convertToPromotions() throws -> CouponHistorySummary {
    try CouponHistorySummary(
      summary: self.summary.toAccountCurrency(),
      totalCoupon: self.totalCount,
      couponHistory: self.payload.map({ p -> CouponHistory in
        try CouponHistory(
          amount: p.coupon.amount.toAccountCurrency(),
          bonusLockReceivingStatus: BonusReceivingStatus.values().get(index: p.coupon.bonusLockStatus)!,
          promotionId: p.coupon.id,
          name: p.coupon.name,
          bonusId: p.coupon.no,
          type: BonusType.convert(p.coupon.type),
          receiveDate: p.coupon.updatedDate.toLocalDateTime(),
          issue: KotlinInt(int: p.coupon.issue),
          productType: ProductType.convert(p.coupon.productType),
          percentage: Percentage(percent: p.coupon.percentage),
          turnOverDetail: p.trial?.toTurnOverTrial())
      }))
  }
}

struct PromotionPayload: Codable {
  var coupon: Coupon
  var trial: Trial?
}

struct Coupon: Codable {
  var amount: Double
  var betMultiple: Int
  var bonusLockStatus: Int32
  var id: String
  var issue: Int32
  var level: Int
  var name: String
  var no: String
  var percentage: Double
  var productType: Int
  var type: Int32
  var updatedDate: String
}

struct Trial: Codable {
  var achieved: Double
  var amount: Double
  var balance: Double
  var formula: String
  var percentage: String
  var request: Double
  var turnoverRequest: Double
  var turnoverRequestForDeposit: Double

  func toTurnOverTrial() -> CouponHistory.TurnOverTrial? {
    CouponHistory.TurnOverTrial(
      achieved: self.achieved.toAccountCurrency(),
      amount: self.amount.toAccountCurrency(),
      balance: self.balance.toAccountCurrency(),
      formula: self.formula,
      percentage: Percentage(percent: self.percentage.doubleValue()),
      request: self.request.toAccountCurrency(),
      turnoverRequest: self.turnoverRequest.toAccountCurrency(),
      turnoverRequestForDeposit: self.turnoverRequestForDeposit.toAccountCurrency())
  }
}

struct ILoginData: Codable {
  var phase: Int
  var isLocked: Bool
  var status: Int
  var platformIsAvailable: Bool
}

struct SkillData: Codable {
  var skillId: String
}

struct PlayerBean: Codable {
  var displayId: String
  var exp: Double
  var gameId: String
  var isAutoUseCoupon: Bool
  var level: Int
  var realName: String
}

struct ProfileBean: Codable {
  var birthday: String?
  var editable: Editable
  var email: String?
  var gameLoginId: String
  var gender: Int
  var loginId: String?
  var mobile: String?
  var realName: String
}

struct Editable: Codable {
  var birthday: Bool
  var email: Bool
  var loginId: Bool
  var mobile: Bool
  var realName: Bool
}

struct ILocalizationData: Codable {
  var cultureCode: String
  var data: [String: String]
}

struct OtpStatus: Codable {
  var isMailActive: Bool
  var isSmsActive: Bool
}

struct DepositTypeData: Codable {
  var depositTypeId: Int32
  var depositTypeName: String
  var isFavorite: Bool
  var depositLimitMaximum: Double
  var depositLimitMinimum: Double
}

struct DepositRecordData: Codable {
  var displayId: String
  var status: Int32
  var ticketType: Int32
  var createdDate: String
  var updatedDate: String
  var requestAmount: Double
  var actualAmount: Double
  var actualAmountWithoutFee: Double
  var isFee: Bool
  var isPendingHold: Bool
}

struct DepositOfflineBankAccountsData: Codable {
  var paymentGroupPaymentCards: [String: PaymentGroupPaymentCard]
}

struct PaymentGroupPaymentCard: Codable {
  var paymentTokenID: String
  var bankID: Int32
  var branch, accountName, accountNumber: String

  enum CodingKeys: String, CodingKey {
    case paymentTokenID = "paymentTokenId"
    case bankID = "bankId"
    case branch, accountName, accountNumber
  }
}

struct SimpleBank: Codable {
  var bankId: Int32
  var name: String
  var shortName: String
}

struct DepositMethodData: Codable {
  var depositTypeID: Int32
  var depositTypeName: String
  var depositMethodID: Int32
  var displayName: String
  var isFavorite: Bool
  var paymentTokenID: String
  var depositLimitMaximum, depositLimitMinimum: Double
  var specialDisplayType: Int
  var providerId: Int
  var amountLimitOptions: [Int32]?

  enum CodingKeys: String, CodingKey {
    case depositTypeID = "depositTypeId"
    case depositTypeName
    case depositMethodID = "depositMethodId"
    case displayName, isFavorite
    case paymentTokenID = "paymentTokenId"
    case depositLimitMaximum, depositLimitMinimum
    case specialDisplayType
    case providerId
    case amountLimitOptions
  }
}

struct DepositTransactionData: Codable {
  let displayID, providerAccountID, depositTransactionID: String
  let bankID: Int?

  enum CodingKeys: String, CodingKey {
    case displayID = "displayId"
    case providerAccountID = "providerAccountId"
    case depositTransactionID = "depositTransactionId"
    case bankID = "bankId"
  }
}

struct OnlineDepositResponse: Codable {
  let transactionId: String
  let displayId: String
}

struct DepositRecordDetailData: Codable {
  let displayID: String
  let requestAmount: Double?
  let actualAmount: Double?
  let actualCryptoAmount: Double?
  let requestCryptoAmount: Double?
  let createdDate, updatedDate: String
  let status: Int32
  let statusChangeHistories: [StatusChangeHistory]
  let isPendingHold: Bool
  let ticketType: Int32
  let fee: Double?
  let actualRate: Double?
  let actualFiatAmount: Double?
  let actualRateDate: String?
  let requestRate: Double?
  let hashId: String?
  let requestRateDate: String?
  let toAddress: String?
  let approvedDate: String?
  let cryptoCurrency: Int?

  enum CodingKeys: String, CodingKey {
    case displayID = "displayId"
    case requestAmount, createdDate, updatedDate, status, statusChangeHistories, isPendingHold, ticketType, fee, actualAmount,
         actualCryptoAmount, actualRate, actualFiatAmount, actualRateDate, hashId, requestRate, requestRateDate, toAddress,
         requestCryptoAmount, approvedDate, cryptoCurrency
  }
}

struct StatusChangeHistory: Codable {
  let remarkLevel1, remarkLevel2, remarkLevel3, createdDate: String
  let imageIDS: [String]

  enum CodingKeys: String, CodingKey {
    case remarkLevel1
    case remarkLevel2
    case remarkLevel3
    case createdDate
    case imageIDS = "imageIds"
  }
}

struct DepositRecordAllData: Codable {
  let date: String
  let logs: [DepositRecordData]
}

// MARK: - Casino
struct TopCasinoResponse: Codable {
  let lobbyID: Int
  let lobbyName: String
  let gameCount: Int
  let casinoData: [CasinoData]?
  let isLobbyMaintenance: Bool
  let games: [CasinoData]?

  enum CodingKeys: String, CodingKey {
    case lobbyID = "lobbyId"
    case lobbyName, gameCount, casinoData, isLobbyMaintenance, games
  }
}

struct CasinoData: Codable {
  let gameID: Int
  let name: String
  let hasForFun, isFavorite: Bool
  let imageID: String
  let isGameMaintenance: Bool
  let isCheckBonusLock: Bool
  let status: Int32
  let releaseDate: String?

  enum CodingKeys: String, CodingKey {
    case gameID = "gameId"
    case imageID = "imageId"
    case isGameMaintenance, status, name, hasForFun, isFavorite, releaseDate, isCheckBonusLock
  }

  func toCasinoGame(host: String) throws -> CasinoGame {
    let thumbnail = CasinoThumbnail(host: host, thumbnailId: self.imageID)
    return try CasinoGame(
      gameId: Int32(self.gameID),
      gameName: self.name,
      isFavorite: self.isFavorite,
      gameStatus: GameStatus.Companion().convert(gameMaintenance: self.isGameMaintenance, status: self.status),
      thumbnail: thumbnail,
      requireNoBonusLock: self.isCheckBonusLock,
      releaseDate: self.releaseDate?.toLocalDate())
  }
}

struct TagBean: Codable {
  let id: Int
  let name: String
  let tagType: Int

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case tagType
  }
}

struct BetSummaryData: Codable {
  let pendingTransactionCount: Int32
  let summaries: [Summary]

  struct Summary: Codable {
    let betDate: String
    let count: Int32
    let stakes: Double
    let winLoss: Double
  }
}

struct CasinoGroupData: Codable {
  let endDate: String
  let lobbyId: Int32
  let lobbyName: String
  let startDate: String
}

struct CasinoBetData: Codable {
  let data: [CasinoBetDetailData]
  let totalCount: Int
}

struct CasinoBetDetailData: Codable {
  let betId: String
  let gameName: String
  let showWinLoss: Bool
  let prededuct: Double
  let stakes: Double
  let wagerId: String
  let winLoss: Double
  let hasDetails: Bool
}

struct CasinoWagerDetail: Codable {
  let betId: String
  let otherId: String
  let betTime: String
  let selection: String
  let roundId: String
  let gameName: String
  let gameResult: String?
  let stakes: Double
  let prededuct: Double
  let winLoss: Double
  let gameType: Int32
  let status: Int32
  let gameProviderId: Int32
}

struct UnsettledSummaryBean: Codable {
  let betTime: String
  let stakes: Double
}

struct UnsettledRecordBean: Codable {
  let betId: String
  let otherId: String
  let gameId: Int32
  let gameName: String
  let betTime: String
  let stakes: Double
  let prededuct: Double
}

struct Nothing: Codable { }

struct NumberGameHotBean: Codable {
  let winLoss: [NumberGameBean]
  let betCount: [NumberGameBean]

  func toHotNumberGames(portalHost: String) -> HotNumberGames {
    HotNumberGames(
      betCountRanking: self.betCount.map { $0.toNumberGame(portalHost: portalHost) },
      winLossRanking: self.winLoss.map { $0.toNumberGame(portalHost: portalHost) })
  }
}

struct NumberGameBean: Codable {
  let gameId: Int32
  let gameName: String?
  let isFavorite: Bool
  let status: Int32
  let imageId: String
  let cultureCode: String
  let hasForFun: Bool
  let isMaintenance: Bool
  let sortingOrder: Int32?

  func toNumberGame(portalHost: String) -> NumberGame {
    NumberGame(
      gameId: gameId,
      gameName: gameName ?? "",
      isFavorite: isFavorite,
      gameStatus: GameStatus.Companion().convert(gameMaintenance: self.isMaintenance, status: self.status),
      thumbnail: NumberGameThumbnail(
        host: portalHost,
        imageId: self.imageId))
  }
}

struct SlotHotGamesBean: Codable {
  let winLoss: [SlotGameBean]
  let betCount: [SlotGameBean]

  func toSlotHotGames(portalHost: String) -> SlotHotGames {
    SlotHotGames(
      mostTransactionRanking: self.betCount.map { $0.toSlotGame(portalHost: portalHost) },
      mostWinningAmountRanking: self.winLoss.map { $0.toSlotGame(portalHost: portalHost) })
  }
}

struct SlotGameBean: Codable {
  let gameId: Int32
  let jackpotPrize: Double
  let isFireGame: Bool
  let status: Int32
  let hasForFun: Bool
  let isFavorite: Bool
  let isGameMaintenance: Bool
  let imageId: String
  let name: String

  func toSlotGame(portalHost: String) -> SlotGame {
    SlotGame(
      gameId: self.gameId,
      gameName: self.name,
      isFavorite: self.isFavorite,
      gameStatus: GameStatus.Companion().convert(gameMaintenance: self.isGameMaintenance, status: self.status),
      thumbnail: SlotThumbnail(host: portalHost, thumbnailId: self.imageId),
      hasForFun: self.hasForFun,
      jackpotPrize: self.jackpotPrize)
  }
}

struct RecentGameBean: Codable {
  let gameId: Int32
  let hasForFun: Bool
  let imageId: String
  let isFavorite: Bool
  let name: String

  func toSlotGame(portalHost: String) -> SlotGame {
    SlotGame(
      gameId: self.gameId,
      gameName: self.name,
      isFavorite: self.isFavorite,
      gameStatus: GameStatus.active,
      thumbnail: SlotThumbnail(host: portalHost, thumbnailId: self.imageId),
      hasForFun: self.hasForFun,
      jackpotPrize: 0)
  }
}

struct SlotBetSummaryBean: Codable {
  let pendingTransactionCount: Int32
  let summaries: [Summary]

  struct Summary: Codable {
    let betDate: String
    let count: Int32
    let stakes: Double
    let winloss: Double

    func toDateSummary() throws -> DateSummary {
      try DateSummary(
        totalStakes: self.stakes.toAccountCurrency(),
        totalWinLoss: self.winloss.toAccountCurrency(),
        createdDateTime: betDate.toLocalDateWithAccountTimeZone(),
        count: self.count)
    }
  }
}

struct SlotNewAndJackpotBean: Codable {
  let newGame: [SlotGameBean]
  let jackpot: [SlotGameBean]

  func toSlotNewAndJackpotGames(portalHost: String) -> SlotNewAndJackpotGames {
    SlotNewAndJackpotGames(
      newGame: self.newGame.map { $0.toSlotGame(portalHost: portalHost) },
      jackpotGames: self.jackpot.map { $0.toSlotGame(portalHost: portalHost) })
  }
}

struct SlotDateGameRecordBean: Codable {
  let count: Int32
  let endDate: String
  let gameId: Int32
  let gameName: String
  let imageId: String
  let stakes: Double
  let startDate: String
  let winloss: Double

  init(gameId: Int32, gameList: [SlotDateGameRecordBean]) {
    self.count = gameList.map({ $0.count }).reduce(0, +)
    self.endDate = gameList.max { a, b -> Bool in a.endDate < b.endDate }?.endDate ?? ""
    self.gameId = gameId
    self.gameName = gameList.first?.gameName ?? ""
    self.imageId = gameList.first?.imageId ?? ""
    self.stakes = gameList.map({ $0.stakes }).reduce(0, +)
    self.startDate = gameList.min(by: { a, b -> Bool in a.startDate < b.startDate })?.startDate ?? ""
    self.winloss = gameList.map({ $0.winloss }).reduce(0, +)
  }

  func toSlotGroupedRecord(host: String) throws -> SlotGroupedRecord {
    let thumbnail = SlotThumbnail(host: host, thumbnailId: imageId)
    return try SlotGroupedRecord(
      slotThumbnail: thumbnail,
      endDate: endDate.toLocalDateTime(),
      gameId: gameId,
      gameName: gameName,
      stakes: stakes.toAccountCurrency(),
      startDate: startDate.toLocalDateTime(),
      winloss: winloss.toAccountCurrency(),
      recordCount: count)
  }
}

struct SlotBetRecordBean: Codable {
  let betId: String
  let betTime: String
  let stakes: Double
  let winLoss: Double
  let hasDetails: Bool

  func toSlotBetRecord() throws -> SlotBetRecord {
    let betLocalTime = try betTime.toLocalDateTime()
    return SlotBetRecord(
      betId: betId,
      betTime: betLocalTime,
      stakes: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency(),
      hasDetails: false)
  }
}

struct SlotUnsettledSummaryBean: Codable {
  let betTime: String
  let stakes: Double

  func toSlotUnsettledSummary() throws -> SlotUnsettledSummary {
    let betLocalTime = try betTime.toLocalDateTime()
    return SlotUnsettledSummary(betTime: betLocalTime)
  }
}

struct SlotUnsettledRecordBean: Codable {
  let betId: String
  let betTime: String
  let gameId: Int32
  let gameName: String
  let otherId: String
  let stakes: Double
  let imageId: String

  func toSlotUnsettledRecord(host: String) throws -> SlotUnsettledRecord {
    let betLocalTime = try betTime.toLocalDateTime()
    let thumbnail = SlotThumbnail(host: host, thumbnailId: imageId)
    return SlotUnsettledRecord(
      betId: betId,
      betTime: betLocalTime,
      gameId: gameId,
      gameName: gameName,
      otherId: otherId,
      stakes: stakes.toAccountCurrency(),
      slotThumbnail: thumbnail)
  }
}

struct NumberGameEntity: Codable {
  let gameId: Int32
  let gameName: String
  let isFavorite: Bool
  let gameStatus: Int32
  let imageId: String
  let cultureCode: String
  let hasForFun: Bool
  let isMaintenance: Bool
  let sortingOrder: Int? = 0

  enum CodingKeys: String, CodingKey {
    case gameName = "name"
    case gameStatus = "status"
    case gameId, isFavorite, imageId, cultureCode, hasForFun, isMaintenance, sortingOrder
  }

  func toNumberGame(portalHost: String) -> NumberGame {
    NumberGame(
      gameId: self.gameId,
      gameName: self.gameName,
      isFavorite: self.isFavorite,
      gameStatus: GameStatus.Companion().convert(gameMaintenance: self.isMaintenance, status: self.gameStatus),
      thumbnail: NumberGameThumbnail(host: portalHost, imageId: self.imageId))
  }
}

struct RecordSummaryResponse: Codable {
  let unsettledSummary: DateSummarynUnSettled
  let settledSummary: DateSummarySettled
  let recentlyBets: [RecentlyBet]
}

struct RecordSummary: Codable {
  let betDate: String
  let count: Int32
  let stakes: Double
  let winLoss: Double

  func toNumberGame() throws -> NumberGameSummary.Date {
    try NumberGameSummary.Date(
      betDate: self.betDate.toLocalDateWithAccountTimeZone(),
      count: count,
      stakes: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency())
  }

  func toUnSettleNumberGame() throws -> NumberGameSummary.Date {
    try NumberGameSummary.Date(
      betDate: self.betDate.toLocalDateWithAccountTimeZone(),
      count: count,
      stakes: stakes.toAccountCurrency(),
      winLoss: nil)
  }
}

struct DateSummarynUnSettled: Codable {
  let details: [RecordSummary]
  let count: Int
}

struct DateSummarySettled: Codable {
  let details: [RecordSummary]
  let count: Int
}

struct RecentlyBet: Codable {
  let betAmount: Double
  let betId: String
  let betTypeName: String
  let gameId: Int32
  let gameName: String
  let hasDetails: Bool
  let isStrike: Bool
  let matchNumber: String
  let selection: String
  let status: Int
  let wagerId: String
  let winLoss: Double

  func toNumberGameRecentlyBet() -> NumberGameSummary.RecentlyBet {
    NumberGameSummary.RecentlyBet(
      wagerId: wagerId,
      selection: selection,
      hasDetail: hasDetails,
      isStrike: isStrike,
      gameId: gameId,
      betTypeName: betTypeName,
      displayId: betId,
      gameName: gameName,
      matchMethod: matchNumber,
      status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss),
      stakes: betAmount.toAccountCurrency())
  }

  static func convertToBetStatus(status: Int, winLoss: Double) -> NumberGameBetDetail.BetStatus {
    switch status {
    case 0: return NumberGameBetDetail.BetStatusUnsettledPending()
    case 1: return NumberGameBetDetail.BetStatusSettledWinLose(winLoss: winLoss.toAccountCurrency())
    case 2: return NumberGameBetDetail.BetStatusSettledCancelled()
    case 3: return NumberGameBetDetail.BetStatusSettledVoid()
    case 4: return NumberGameBetDetail.BetStatusUnsettledConfirmed()
    case 5: return NumberGameBetDetail.BetStatusSettledSelfCancelled()
    case 6: return NumberGameBetDetail.BetStatusSettledStrikeCancelled()
    default: return NumberGameBetDetail.BetStatusSettledCancelled()
    }
  }
}

struct NumberGameBetDetailBean: Codable {
  let betId: String?
  let betTime: String
  let displayId: String
  let gameName: String
  let matchNumber: String
  let resultNumber: String?
  let selections: [String]
  let stakes: Double
  let status: Int
  let winLoss: Double
  let gameResultDisplayType: Int32

  func toNumberGameBetDetail() throws -> NumberGameBetDetail {
    let betLocalTime = try betTime.toLocalDateTime()
    return NumberGameBetDetail(
      displayId: displayId,
      traceId: betId,
      gameName: gameName,
      matchMethod: matchNumber,
      betContent: selections,
      betTime: betLocalTime,
      stakes: stakes.toAccountCurrency(),
      status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss),
      resultType: GameResultType.companion.parse(value: gameResultDisplayType),
      _result: resultNumber)
  }
}

struct GameGroupBetSummaryResponse: Codable {
  var data: [GameBetSummaryData]
  var totalCount: Int
}

struct GameBetSummaryData: Codable {
  var count: Int32
  var gameId: Int32
  var gameName: String
  var imageId: String
  var maxDate: String
  var stakes: Double
  var winLoss: Double

  func toUnSettleGameSummary(portalHost: String) -> NumberGameSummary.Game {
    NumberGameSummary.Game(
      gameId: gameId,
      gameName: gameName,
      thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId),
      totalRecords: count,
      betAmount: stakes.toAccountCurrency(),
      winLoss: nil)
  }

  func toSettleGameSummary(portalHost: String) -> NumberGameSummary.Game {
    NumberGameSummary.Game(
      gameId: gameId,
      gameName: gameName,
      thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId),
      totalRecords: count,
      betAmount: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency())
  }
}

struct BetsSummaryResponse: Codable {
  var data: [BetSummaryDataResponse]
  var totalCount: Int
}

struct BetSummaryDataResponse: Codable {
  var betId: String
  var betTime: String
  var hasDetails: Bool
  var settleTime: String
  var stakes: Double
  var wagerId: String
  var winLoss: Double

  func toUnSettleGameSummary() throws -> NumberGameSummary.Bet {
    try NumberGameSummary.Bet(
      displayId: betId,
      wagerId: wagerId,
      time: betTime.toLocalDateTime(),
      betAmount: stakes.toAccountCurrency(),
      winLoss: nil,
      hasDetail: hasDetails)
  }

  func toSettleGameSummary() throws -> NumberGameSummary.Bet {
    try NumberGameSummary.Bet(
      displayId: betId,
      wagerId: wagerId,
      time: settleTime.toLocalDateTime(),
      betAmount: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency(),
      hasDetail: hasDetails)
  }
}

struct CryptoDepositReceipt: Codable {
  var displayId: String
  var url: String
}

struct CryptoDepositUrl: Codable {
  var url: String
}

struct ContactInfoBean: Codable {
  let mobile: String?
  let email: String?
}

struct P2PTurnOverBean: Codable {
  let bonusLocked: Bool
  let hasBonusTag: Bool
  let currentBonus: LockedBonusDataBean?
}

struct LockedBonusDataBean: Codable {
  let achieved: String
  let formula: String
  let informPlayerDate: String
  let name: String
  let no: String
  let remainingAmount: String
  let parameters: Parameters
  let type: Int
  let productType: Int

  func toTurnOverReceipt() throws -> P2PTurnOver.TurnOverReceipt {
    let informPlayerDate = try self.informPlayerDate.toOffsetDateTime()
    let parameter = toTurnOverDetailParameters(parameters)

    return P2PTurnOver.TurnOverReceipt(
      turnOverDetail: TurnOverDetail(
        achieved: achieved.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
        formula: formula,
        informPlayerDate: informPlayerDate,
        name: name,
        bonusId: no,
        remainAmount: remainingAmount.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
        parameters: parameter))
  }

  func toTurnOverDetail() throws -> TurnOverDetail {
    try TurnOverDetail(
      achieved: achieved.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      formula: formula, informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      name: self.name,
      bonusId: self.no,
      remainAmount: self.remainingAmount.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      parameters: self.toTurnOverDetailParameters(self.parameters))
  }

  private func toTurnOverDetailParameters(_: Parameters) -> TurnOverDetail.Parameters {
    TurnOverDetail.Parameters(
      amount: parameters.amount.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      balance: parameters.balance.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      betMultiplier: Int32(parameters.betMultiplier),
      capital: parameters.capital.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      depositRequest: parameters.depositRequest.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      percentage: Percentage(percent: parameters.percentage.currencyAmountToDouble() ?? 0),
      request: parameters.request.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      requirement: parameters.requirement.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
      turnoverRequest: parameters.turnoverRequest.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency())
  }
}

struct Parameters: Codable {
  let amount: String
  let balance: String
  var betMultiplier: Int { _betMultiplier ?? 0 }
  let capital: String
  let depositRequest: String
  let percentage: String
  let request: String
  let requirement: String
  let turnoverRequest: String

  private var _betMultiplier: Int?

  enum CodingKeys: String, CodingKey {
    case _betMultiplier = "betMultiplier"
    case amount, capital, request, turnoverRequest, requirement, percentage, balance, depositRequest
  }
}

struct P2PGameBean: Codable {
  let gameId: Int32
  let hasForFun: Bool
  let imageCulture: String
  let imageId: String
  let name: String
  let providerId: Int
  let status: Int32
}

struct P2PBetSummaryBean: Codable {
  let summaries: [SummaryBean]
}

struct SummaryBean: Codable {
  let betDate: String
  let count: Int32
  let stakes: Double
  let winLoss: Double

  func toDateSummary() throws -> DateSummary {
    try DateSummary(
      totalStakes: self.stakes.toAccountCurrency(),
      totalWinLoss: self.winLoss.toAccountCurrency(),
      createdDateTime: betDate.toLocalDateWithAccountTimeZone(),
      count: self.count)
  }
}

struct ArcadeSummaryBean: Codable {
  let summaries: [SummaryBean]
}

struct P2PDateBetRecordBean: Codable {
  let count: Int32
  let endDate: String
  let gameGroupId: Int32
  let gameName: String
  let stakes: Double
  let startDate: String
  let winLoss: Double
  let imageId: String

  init(gameGroupId: Int32, gameList: [P2PDateBetRecordBean]) {
    self.count = gameList.map({ $0.count }).reduce(0, +)
    self.endDate = gameList.max { a, b -> Bool in a.endDate < b.endDate }?.endDate ?? ""
    self.gameGroupId = gameGroupId
    self.gameName = gameList.first?.gameName ?? ""
    self.stakes = gameList.map({ $0.stakes }).reduce(0, +)
    self.startDate = gameList.min(by: { a, b -> Bool in a.startDate < b.startDate })?.startDate ?? ""
    self.winLoss = gameList.map({ $0.winLoss }).reduce(0, +)
    self.imageId = gameList.first?.imageId ?? ""
  }

  func toGameGroupedRecord(host: String) throws -> GameGroupedRecord {
    let thumbnail = P2PThumbnail(host: host, thumbnailId: imageId)
    return try GameGroupedRecord(
      gameId: gameGroupId,
      gameName: gameName,
      thumbnail: thumbnail,
      recordsCount: count,
      stakes: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency(),
      startDate: startDate.toLocalDateTime(),
      endDate: endDate.toLocalDateTime())
  }
}

struct ArcadeDateDataRecordBean: Codable {
  let gameName: String
  let gameId: Int32
  let stakes: Double
  let winLoss: Double
  let startDate: String
  let endDate: String
  let imageId: String
  let count: Int32

  init(gameId: Int32, gameList: [ArcadeDateDataRecordBean]) {
    self.count = gameList.map({ $0.count }).reduce(0, +)
    self.endDate = gameList.max { a, b -> Bool in a.endDate < b.endDate }?.endDate ?? ""
    self.gameId = gameId
    self.gameName = gameList.first?.gameName ?? ""
    self.stakes = gameList.map({ $0.stakes }).reduce(0, +)
    self.startDate = gameList.min(by: { a, b -> Bool in a.startDate < b.startDate })?.startDate ?? ""
    self.winLoss = gameList.map({ $0.winLoss }).reduce(0, +)
    self.imageId = gameList.first?.imageId ?? ""
  }

  func toGameGroupedRecord(host: String) throws -> GameGroupedRecord {
    let thumbnail = P2PThumbnail(host: host, thumbnailId: imageId)
    return try GameGroupedRecord(
      gameId: gameId,
      gameName: gameName,
      thumbnail: thumbnail,
      recordsCount: count,
      stakes: stakes.toAccountCurrency(),
      winLoss: winLoss.toAccountCurrency(),
      startDate: startDate.toLocalDateTime(),
      endDate: endDate.toLocalDateTime())
  }
}

struct ArcadeDateBetRecordBean: Codable {
  let data: [ArcadeDateDataRecordBean]
}

struct P2PGameBetRecordBean: Codable {
  let betTime: String
  let gameGroupId: Int32
  let gameName: String
  let groupId: String
  let hasDetails: Bool
  let prededuct: Double
  let stakes: Double
  let wagerId: String
  let winLoss: Double

  func toP2PGameBetRecord() throws -> P2PGameBetRecord {
    let betLocalTime = try betTime.toLocalDateTime()
    return P2PGameBetRecord(
      betTime: betLocalTime,
      gameGroupId: gameGroupId,
      gameName: gameName,
      groupId: groupId,
      hasDetails: hasDetails,
      prededuct: prededuct.toAccountCurrency(),
      stakes: stakes.toAccountCurrency(),
      wagerId: wagerId,
      winLoss: winLoss.toAccountCurrency())
  }
}

struct ArcadeGameBetRecordDataBean: Codable {
  let data: [ArcadeGameBetRecordBean]
}

struct ArcadeGameBetRecordBean: Codable {
  let stakes: Double
  let winLoss: Double
  let wagerId: String
  let betId: String
  let betTime: String
  let settleTime: String
  let hasDetails: Bool

  func toArcadeGameBetRecord() throws -> ArcadeGameBetRecord {
    try ArcadeGameBetRecord(
      wagerId: self.wagerId,
      betId: self.betId,
      betTime: self.betTime.toOffsetDateTime(),
      settleTime: self.settleTime.toOffsetDateTime(),
      hasDetails: self.hasDetails,
      stakes: self.stakes.toAccountCurrency(),
      winLoss: self.winLoss.toAccountCurrency())
  }
}

struct ArcadeGameBean: Codable {
  let recommendGames: [ArcadeGameDataBean]
  let newGames: [ArcadeGameDataBean]
  let allGames: [ArcadeGameDataBean]
}

struct ArcadeGameDataBean: Codable {
  let gameId: Int32
  let name: String
  let hasForFun: Bool
  let isNew: Bool
  let isRecommend: Bool
  let isFavorite: Bool
  let isHot: Bool
  let imageId: String
  let isMaintenance: Bool
  let status: Int32
  let transactionCount: Int32
  let cultureCode: String?
  let releaseDate: String?
  let providerId: Int
  let isCheckBonusLock: Bool

  func toArcadeGame(host: String) -> ArcadeGame {
    ArcadeGame(
      gameId: gameId,
      gameName: name,
      isFavorite: isFavorite,
      gameStatus: GameStatus.Companion().convert(gameMaintenance: self.isMaintenance, status: self.status),
      thumbnail: ArcadeThumbnail(host: host, thumbnailId: imageId),
      requireNoBonusLock: isCheckBonusLock)
  }
}

struct LevelBean: Codable {
  let data: [PrivilegeBean]?
  let level: Int32
  let timestamp: String
}

struct PrivilegeBean: Codable {
  let betMultiple: Int32
  let casinoPercentage: Double
  let issueFrequency: Int32
  let numberGamePercentage: Double
  let maxBonus: Double
  let minCapital: Double
  let percentage: Double
  let productType: Int32
  let sbkPercentage: Double
  let slotPercentage: Double
  let arcadePercentage: Double
  let type: Int32
  let withdrawalLimitAmount: Double
  let withdrawalLimitCount: Int32
}

struct BonusBean: Codable {
  struct Coupon: Codable {
    let amount: Double
    let away: String
    let betMultiple: Int32
    let bonusCouponStatus: Int32
    let displayId: String
    let home: String
    let informPlayerDate: String
    let isLimitedByDailyFull: Bool?
    let issueNumber: Int32
    let league: String
    let level: Int32
    let maxAmount: Double
    let name: String
    let no: String
    let percentage: Double
    let productType: Int32
    let fixTurnoverRequirement: Double
    let type: Int32
    let minCapital: Double

    @DefaultCodable(String.minimumDate) var effectiveDate: String
    @DefaultCodable(String.maximumDate) var expiryDate: String
    @DefaultCodable(String.minimumDate) var updatedDate: String
  }

  struct Promotion: Codable {
    let informPlayerDate: String
    let displayId: String
    let endDate: String
    let issue: Int32
    let maxAmount: Double
    let name: String?
    let productType: Int32
    let sort: Int32?
    let type: Int32

    @DefaultCodable(Bool.false) var isAutoUse: Bool
    @DefaultCodable(Double.zero) var percentage: Double
  }

  var coupons: [Coupon] = []
  var productPromotions: [Promotion] = []
  var rebatePromotions: [Promotion] = []
  var cashbackPromotions: [Promotion] = []
}

extension BonusBean.Coupon {
  var couponStatus: CouponStatus {
    self.covertBonusPromotionStatus(self.bonusCouponStatus, isLimitedByDailyFull)
  }

  var knAmount: AccountCurrency {
    self.amount.toAccountCurrency()
  }

  var knMaxAmount: sharedbu.Promotion.IMaxAmount {
    sharedbu.Promotion.companion.create(amount: self.maxAmount.toAccountCurrency())
  }

  var knMinCapital: AccountCurrency {
    self.minCapital.toAccountCurrency()
  }

  var knPercentage: Percentage {
    Percentage(percent: self.percentage)
  }

  private func covertBonusPromotionStatus(_ bonusCouponStatus: Int32, _ isLimitedByDailyFull: Bool?) -> CouponStatus {
    CouponStatus.companion.convert(status: bonusCouponStatus, reachedDailyLimit: isLimitedByDailyFull ?? false)
  }

  func toBonusCoupon() throws -> BonusCoupon {
    switch self.type {
    case 1:
      return try self.toFreebet()
    case 2:
      return try self.toDepositReturnCustomize()
    case 3:
      return try self.toProduct()
    case 4:
      return try self.toRebate()
    case 5:
      return try self.toDepositReturnLevel()
    case 7:
      return try self.toVVIPCashback()
    default:
      return BonusCoupon.Other()
    }
  }

  private func toFreebet() throws -> BonusCoupon {
    try BonusCoupon.FreeBet(
      promotionId: self.displayId,
      bonusId: self.no,
      name: self.name,
      couponStatus: self.couponStatus,
      percentage: self.knPercentage,
      amount: self.knAmount,
      maxAmount: self.knMaxAmount,
      betMultiple: self.betMultiple,
      fixTurnoverRequirement: self.fixTurnoverRequirement,
      informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      updatedDate: self.updatedDate.toLocalDateTime(),
      validPeriod: ValidPeriod.Companion().create(
        start: self.effectiveDate.toOffsetDateTime(),
        end: self.expiryDate.toOffsetDateTime()),
      minCapital: self.knMinCapital)
  }

  private func toDepositReturnCustomize() throws -> BonusCoupon {
    try BonusCoupon.DepositReturnCustomize(property: self.toDepositReturnProperty())
  }

  private func toProduct() throws -> BonusCoupon {
    try BonusCoupon.Product(
      promotionId: self.displayId,
      bonusId: self.no,
      issueNumber: self.issueNumber,
      productType: ProductType.convert(self.productType),
      informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      maxAmount: self.knMaxAmount,
      endDate: self.effectiveDate.toLocalDateTime(),
      name: self.name,
      betMultiple: self.betMultiple,
      fixTurnoverRequirement: self.fixTurnoverRequirement,
      validPeriod: ValidPeriod.Companion().create(
        start: self.effectiveDate.toOffsetDateTime(),
        end: self.expiryDate.toOffsetDateTime()),
      updatedDate: self.updatedDate.toLocalDateTime(),
      couponStatus: self.couponStatus,
      minCapital: self.knMinCapital)
  }

  private func toRebate() throws -> BonusCoupon {
    let property = try BonusCoupon.Property(
      promotionId: self.displayId,
      bonusId: self.no,
      name: self.name,
      issueNumber: self.issueNumber == 0 ? nil : KotlinInt(value: self.issueNumber),
      percentage: self.knPercentage,
      amount: self.knAmount,
      endDate: self.effectiveDate.toLocalDateTime(),
      betMultiple: self.betMultiple,
      fixTurnoverRequirement: self.fixTurnoverRequirement,
      validPeriod: ValidPeriod.Companion().create(
        start: self.effectiveDate.toOffsetDateTime(),
        end: self.expiryDate
          .toOffsetDateTime()),
      couponStatus: self.couponStatus,
      updatedDate: self.updatedDate.toLocalDateTime(),
      informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      minCapital: self.knMinCapital)
    return BonusCoupon.Rebate(property: property, rebateFrom: ProductType.convert(self.productType))
  }

  private func toDepositReturnLevel() throws -> BonusCoupon {
    try BonusCoupon.DepositReturnLevel(level: self.level, property: self.toDepositReturnProperty())
  }

  private func toDepositReturnProperty() throws -> BonusCoupon.DepositReturnProperty {
    try BonusCoupon.DepositReturnProperty(
      promotionId: self.displayId,
      bonusId: self.no,
      couponStatus: self.couponStatus,
      percentage: self.knPercentage,
      amount: self.knAmount,
      maxAmount: self.knMaxAmount,
      betMultiple: self.betMultiple,
      fixTurnoverRequirement: self.fixTurnoverRequirement,
      informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      updatedDate: self.updatedDate.toLocalDateTime(),
      name: self.name,
      validPeriod: ValidPeriod.Companion().create(
        start: self.effectiveDate.toOffsetDateTime(),
        end: self.expiryDate.toOffsetDateTime()),
      minCapital: self.knMinCapital)
  }

  private func toVVIPCashback() throws -> BonusCoupon.VVIPCashback {
    try BonusCoupon.VVIPCashback(property: BonusCoupon.Property(
      promotionId: self.displayId,
      bonusId: self.no,
      name: self.name,
      issueNumber: KotlinInt(value: Int32(self.issueNumber)),
      percentage: self.knPercentage,
      amount: self.knAmount,
      endDate: self.effectiveDate.toLocalDateTime(),
      betMultiple: self.betMultiple,
      fixTurnoverRequirement: self.fixTurnoverRequirement,
      validPeriod: ValidPeriod.Companion()
        .create(
          start: self.effectiveDate.toOffsetDateTime(),
          end: self
            .expiryDate
            .toOffsetDateTime(
            )),
      couponStatus: self.couponStatus,
      updatedDate: self.updatedDate.toLocalDateTime(),
      informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
      minCapital: self.knMinCapital))
  }
}

extension BonusBean.Promotion {
  func toCashbackPromotion() throws -> PromotionEvent.VVIPCashback {
    try PromotionEvent.VVIPCashbackCompanion()
      .create(
        promotionId: self.displayId,
        issueNumber: self.issue,
        informPlayerDate: self.informPlayerDate.toLocalDateTime(),
        percentage: Percentage(percent: self.percentage),
        maxBonusAmount: self.maxAmount.toAccountCurrency(),
        endDate: self.endDate.toOffsetDateTime())
  }

  func toProductPromotion() throws -> PromotionEvent.Product {
    try PromotionEvent.ProductCompanion()
      .create(
        promotionId: self.displayId,
        issueNumber: self.issue,
        informPlayerDate: self.informPlayerDate.toLocalDateTime(),
        endDate: self.endDate.toOffsetDateTime(),
        maxBonusAmount: self.maxAmount.toAccountCurrency(),
        type: ProductType.convert(self.productType))
  }

  func toRebatePromotion() throws -> PromotionEvent.Rebate {
    try PromotionEvent.RebateCompanion()
      .create(
        promotionId: self.displayId,
        issueNumber: self.issue,
        informPlayerDate: self.informPlayerDate.toLocalDateTime(),
        type: ProductType.convert(self.productType),
        percentage: Percentage(percent: self.percentage),
        maxBonusAmount: self.maxAmount.toAccountCurrency(),
        endDate: self.endDate.toOffsetDateTime(),
        isAutoUse: self.isAutoUse)
  }
}

struct LockBonusBean: Codable {
  let amount: Double?
  let betMultiple: Int32?
  let capital: Double?
  let fixTurnoverRequirement: Double?
  let maxAmount: Double?
  let name: String?
  let no: String?
  let percentage: Double?
  let playerLevel: Int32?
  let productType: Int32?
  var status: BonusCouponStatus? {
    if let value = _status {
      return BonusCouponStatus(rawValue: value)
    }
    return nil
  }

  let type: Int32?
  private var _status: Int32?

  enum CodingKeys: String, CodingKey {
    case amount
    case betMultiple
    case capital
    case fixTurnoverRequirement
    case maxAmount
    case name
    case no
    case percentage
    case playerLevel
    case productType
    case type
    case _status = "status"
  }

  enum BonusCouponStatus: Int32 {
    case Usable
    case Used
    case Expired
    case Full
  }
}

struct BonusTagBean: Codable {
  let hasBonusTag: Bool
}

struct BonusHintBean: Codable {
  let formula: String
  let parameters: Parameters

  struct Parameters: Codable {
    let amount: String?
    let balance: String?
    let betMultiplier: Int?
    let capital: String?
    let request: String?
    let requirement: String?

    private func toCashAmount(_ text: String?) -> AccountCurrency {
      text?.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency()
    }

    fileprivate func toTurnOverHintParameters() -> TurnOverHint.Parameters {
      TurnOverHint.Parameters(
        amount: toCashAmount(self.amount),
        balance: toCashAmount(self.balance),
        betMultiplier: Int32(betMultiplier ?? 0),
        capital: toCashAmount(self.capital),
        request: toCashAmount(self.request),
        requirement: toCashAmount(self.requirement))
    }
  }

  func toTurnOverHint() -> TurnOverHint {
    TurnOverHint(formula: self.formula, parameters: self.parameters.toTurnOverHintParameters())
  }
}

struct PromotionContentBean: Codable {
  let content: String
  let rules: String
}

struct PromotionTemplateBean: Codable {
  let contentTemplate: String
  let rulesTemplate: String

  func toPromotionDescriptions() -> PromotionDescriptions {
    PromotionDescriptions(content: self.contentTemplate, rules: self.rulesTemplate)
  }
}

struct BalanceLogDetailBean: Codable {
  let afterBalance: Double
  let amount: Double
  let createdDate: String
  let createdUser: String
  let description: String?
  let displayId: String?
  let externalId: String
  let previousBalance: Double
  let productProvider: Int32
  let productType: Int32
  let transactionType: Int32
  let wagerMappingId: String?

  func toBalanceLogDetail(remark: BalanceLogDetailRemark? = nil) throws -> BalanceLogDetail {
    try BalanceLogDetail(
      afterBalance: afterBalance.toAccountCurrency(),
      amount: amount.toAccountCurrency(),
      date: createdDate.toLocalDateTime(),
      wagerMappingId: wagerMappingId ?? externalId,
      productGroup: ProductProviders.Companion().createProductGroup(provider: productProvider),
      productType: ProductType.convert(productType),
      transactionType: TransactionTypes.Companion().create(type: transactionType),
      remark: remark ?? BalanceLogDetailRemark.None(),
      externalId: externalId)
  }
}

struct _BalanceLogBonusRemarkBean: Codable {
  let amount: Double
  let away: String
  let betMultiple: Int32
  let bonusCouponStatus: Int32
  let displayId: String
  let effectiveDate: String
  let expiryDate: String
  let fixTurnoverRequirement: Double
  let home: String
  let informPlayerDate: String
  let issue: Int32
  let issueNumber: Int32
  let league: String
  let level: Int32
  let maxAmount: Double
  let minCapital: Double
  let name: String
  let no: String
  let percentage: Double
  let productType: Int32
  let type: Int32
  let updatedDate: String
  let cashbackRemark: CashBackRemarkBean?

  func toBalanceLogDetailRemark() -> BalanceLogDetailRemark {
    if let cashbackRemark {
      return BalanceLogDetailRemark.CashBack(
        title: name,
        issueNumber: IssueNumber.Companion().create(yearMonth: String(issueNumber)),
        bonusId: no,
        arcade: cashbackRemark.arcade.toAccountCurrency(),
        casino: cashbackRemark.casino.toAccountCurrency(),
        numberGame: cashbackRemark.numberGame.toAccountCurrency(),
        percent: Percentage(percent: cashbackRemark.percent),
        sbk: cashbackRemark.sbk.toAccountCurrency(),
        slot: cashbackRemark.slot.toAccountCurrency(),
        totalBonusAmount: cashbackRemark.totalBonusAmount.toAccountCurrency(),
        totalWinLoss: cashbackRemark.totalWinLoss.toAccountCurrency())
    }
    else {
      return BalanceLogDetailRemark.Bonus(
        bonusId: no,
        bonusName: name,
        bonusType: BonusType.convert(type),
        issueNumber: issueNumber,
        productType: ProductType.convert(productType))
    }
  }
}

struct CashBackRemarkBean: Codable {
  let sbk: Double
  let casino: Double
  let slot: Double
  let numberGame: Double
  let arcade: Double
  let totalWinLoss: Double
  let totalBonusAmount: Double
  let percent: Double
}

struct _BalanceLogDetailRemarkBean: Codable {
  let betStatus: Int32
  let description: String?
  let displayIds: [String?]?
  let gameName: String?
  let isDetail: Bool
  let lobbyName: String?
  let productProvider: Int32
  let productType: Int32
  let wagerId: [String]?

  func toBalanceLogDetailRemark(isTransferWallet: Bool) -> BalanceLogDetailRemark {
    if lobbyName.isNullOrEmpty(), displayIds.isNullOrEmpty(), wagerId.isNullOrEmpty() {
      return BalanceLogDetailRemark.None()
    }
    else if isTransferWallet {
      return BalanceLogDetailRemark.TransferWallet(
        betStatus: BetStatus_.convert(betStatus),
        lobbyName: lobbyName ?? "",
        ids: createPairedArray(),
        isDetailActive: isDetail)
    }
    else {
      return BalanceLogDetailRemark.General(
        betStatus: BetStatus_.convert(betStatus),
        lobbyName: lobbyName ?? "",
        ids: createPairedArray())
    }
  }
  
  private func createPairedArray() -> [KotlinPair<NSString, NSString>] {
    guard
      let displayIds = displayIds?.compactMap({ $0 as? NSString }),
      let wagerId = wagerId?.compactMap({ $0 as NSString }),
      displayIds.count == wagerId.count
    else { return [] }
    
    return displayIds
      .enumerated()
      .map { index, element in
        KotlinPair(first: element, second: wagerId[index])
      }
  }
}

struct CashBackSettingBean: Codable, Equatable {
  let lossAmountRange: String
  let maxAmount: String
  let cashBackPercentage: String
}

struct PlayerInChatBean: Codable {
  let skillId: String

  var roomId: String { _roomId ?? "" }
  var token: String { _token ?? "" }

  private let _roomId: String?
  private let _token: String?

  enum CodingKeys: String, CodingKey {
    case _roomId = "roomId"
    case _token = "token"
    case skillId
  }
}

struct InProcessBean: Codable {
  let chatEventType: Int
  let createdDate: String
  let message: Message
  let messageId: Int32
  let playerRead: Bool
  let remark: String
  let speaker: String
  let speakerId: String
  let speakerType: Int32
  let text: String
}

struct SkillSurveyData: Codable {
  let skillID: String
  let survey: SurveyBean?

  enum CodingKeys: String, CodingKey {
    case skillID = "skillId"
    case survey
  }
}

struct PreChatAnswerSurveyBean: Codable {
  let answerSurvey: AnswerSurveyBean
}

struct ExitAnswerSurveyBean: Codable {
  let questions: [Question]
  let roomId: String
  let skillId: String
  let surveyType: Int32
}

struct AnswerSurveyBean: Codable {
  let questions: [Question]
}

struct Question: Codable {
  let questionId: String
  let questionText: String
  let surveyAnswerOptions: [SurveyAnswerOption]
}

struct SurveyAnswerOption: Codable {
  let optionId: String?
  let optionText: String
}

struct SurveyBean: Codable {
  let copyFrom: String
  let createdDate: String
  let createdUser: String?
  let description: String?
  let enable: Bool
  let heading: String?
  let isAskLogin: Bool
  let isEverOnline: Bool
  let isOnline: Bool
  let skillId: String
  let subject: String?
  let surveyId: String
  let surveyQuestions: [SurveyQuestionBean]?
  let surveyType: Int32
  let updatedDate: String
  let updatedUser: String?
  let version: Int32

  func toSurvey() -> Survey {
    Survey(
      csSkillId: skillId,
      surveyId: surveyId,
      description: description ?? "",
      surveyType: convertSurveyType(surveyType),
      surveyQuestions: surveyQuestions?.map { $0.toSurveyQuestion() } ?? [],
      enable: enable,
      heading: heading ?? "",
      isAskLogin: isAskLogin,
      isEverOnline: isEverOnline,
      isOnline: isOnline,
      mailFooter: "",
      subject: subject ?? "",
      version: version,
      updatedUser: updatedUser ?? "")
  }

  private func convertSurveyType(_ surveyType: Int32) -> Survey.SurveyType {
    switch surveyType {
    case 0: return .prechat
    case 1: return .exit
    default: return .unknown
    }
  }
}

struct SurveyQuestionBean: Codable {
  let aim: String
  let createdDate: String
  let createdUser: String
  let description: String
  let enable: Bool
  let isLogin: Bool
  let isNotLogin: Bool
  let isRequired: Bool
  let isVisible: Bool
  let questionId: String
  let sort: Int32
  let surveyId: String
  let surveyQuestionOptions: [SurveyQuestionOption]
  let surveyQuestionType: Int32

  func toSurveyQuestion() -> SurveyQuestion_ {
    SurveyQuestion_(
      questionId: questionId,
      aim: aim,
      createdDate: createdDate,
      description: description,
      enable: enable,
      isLogin: isLogin,
      isNotLogin: isNotLogin,
      isRequired: isRequired,
      isVisible: isVisible,
      sort: sort,
      surveyId: surveyId,
      surveyQuestionOptions: surveyQuestionOptions.map { $0.toSurveyQuestionOption() },
      surveyQuestionType: convert(surveyQuestionType))
  }

  func convert(_ surveyQuestionType: Int32) -> SurveyQuestion_.SurveyQuestionType {
    switch surveyQuestionType {
    case 1: return .simpleoption
    case 2: return .multipleoption
    case 6: return .textfield
    default: fatalError("unknown surveyQuestionType : \(surveyQuestionType)")
    }
  }
}

struct SurveyQuestionOption: Codable {
  let createdDate: String
  let createdUser: String
  let enable: Bool
  let isOther: Bool
  let optionId: String
  let questionId: String
  let values: String

  func toSurveyQuestionOption() -> SurveyQuestion_.SurveyQuestionOption {
    SurveyQuestion_.SurveyQuestionOption(
      optionId: optionId,
      questionId: questionId,
      enable: enable,
      isOther: isOther,
      values: values)
  }
}

struct ChatMessageBean: Codable {
  let createTimeTick: String
  let fileId: String?
  let html: String
  let messageId: Int32
  let messageType: Int32
  let speaker: String
  let speakerType: Int32
  let text: String
}

struct OldChatHistories: Codable {
  let payload: [Payload]
  let totalCount: Int

  struct Payload: Codable {
    let createdDate: String
    let roomId: String
    let title: String?

    func toChatHistory(timeZone _: Foundation.TimeZone) throws -> ChatHistory {
      try ChatHistory(createDate: createdDate.toLocalDateTime(), title: title ?? "", roomId: roomId)
    }
  }
}

struct ChatHistoryBean: Codable {
  let currencyCode: Int
  let roomHistories: [RoomHistory]
  let roomId: String
  let roomNo: String?
}

struct RoomHistory: Codable {
  let chatEventType: Int
  let createdDate: String
  let message: Message
  let messageId: Int32
  let messageType: Int
  let playerRead: Bool
  let remark: String
  let speaker: String
  let speakerId: String
  let speakerType: Int32
  let text: String
}

struct Message: Codable {
  let quillDeltas: [QuillDelta]
}

struct QuillDelta: Codable {
  let attributes: Attributes?
  let insert: String
}

struct Attributes: Codable {
  var align: Int? = nil
  var background: String? = nil
  var bold: Bool? = nil
  var color: String? = nil
  var font: String? = nil
  var image: String? = nil
  var italic: Bool? = nil
  var link: String? = nil
  var size: String? = nil
  var underline: Bool? = nil

  func convert() -> sharedbu.Attributes {
    sharedbu.Attributes(
      align: KotlinInt(value: Int32(align ?? 0)),
      background: background,
      bold: KotlinBoolean(value: bold ?? false),
      color: color,
      font: font,
      image: image,
      italic: KotlinBoolean(value: italic ?? false),
      link: link,
      size: size,
      underline: KotlinBoolean(value: underline ?? false))
  }
  
  func convert() -> sharedbu.Attributes_ {
    sharedbu.Attributes_(
      align: KotlinInt(value: Int32(align ?? 0)),
      background: background,
      bold: KotlinBoolean(value: bold ?? false),
      color: color,
      font: font,
      image: image,
      italic: KotlinBoolean(value: italic ?? false),
      link: link,
      size: size,
      underline: KotlinBoolean(value: underline ?? false))
  }
}

struct SpeakingAsyncBean: Codable {
  let createdDate: String
  let message: Message
  let messageId: Int32
  let messageType: Int
  let playerRead: Bool
  let roomId: String
  let speaker: String
  let speakerId: String
  let speakerType: Int32
  let text: String
}

struct ActivityMessagePageBean: Codable {
  let documents: [ActivityMessageBean]
  let totalCount: Int32
}

struct ActivityMessageBean: Codable {
  let myActivityType: Int32
  let categoryId: Int
  let itemId: String
  let displayId: String
  let value: String?
  let notifyTitle: String
  let notifyContent: String
  let afterBalance: String?
  let dateInfo: String
}

struct InternalMessagePageBean: Codable {
  let documents: [InternalMessageBean]
  let totalCount: Int32
}

struct InternalMessageBean: Codable {
  let messageId: String
  let messageType: Int
  let title: String
  let message: String
  let showTime: String?
  let closeTime: String?
  let maintenanceStartTime: String?
  let maintenanceEndTime: String?
  let currencyCode: Int
}

struct CryptoCurrencyInfo: Codable {
  let cryptoCurrency: Int
  let isEnableDepositFee: Bool
  let feePercentage: Double
  let maximumFee: Int
}

struct ProductStatusBean: Codable {
  let numberGameMaintenanceEndTime: String?
  let sbkMaintenanceEndTime: String?
  let slotMaintenanceEndTime: String?
  let casinoMaintenanceEndTime: String?
  let p2pMaintenanceEndTime: String?
  let arcadeMaintenanceEndTime: String?
  let productsAvailable: [Int]

  func toMaintenanceStatus() throws -> MaintenanceStatus {
    try MaintenanceStatus.Product(
      productsAvailable: productsAvailable.map { ProductType.convert($0) },
      status: [
        ProductType.numbergame: numberGameMaintenanceEndTime?.toOffsetDateTime() as Any,
        ProductType.sbk: sbkMaintenanceEndTime?.toOffsetDateTime() as Any,
        ProductType.slot: slotMaintenanceEndTime?.toOffsetDateTime() as Any,
        ProductType.casino: casinoMaintenanceEndTime?.toOffsetDateTime() as Any,
        ProductType.p2p: p2pMaintenanceEndTime?.toOffsetDateTime() as Any,
        ProductType.arcade: arcadeMaintenanceEndTime?.toOffsetDateTime() as Any
      ])
  }
}

struct VersionData: Codable {
  let ipaCapacity: String
  let ipaVersion: String
  let ipaVersionHash: String
  let downloadUrl: String
  let downloadUrlVn: String

  func toVersion() -> Version {
    Version.companion.create(version: ipaVersion, link: getDownloadLink(), size: ipaCapacity.doubleValue())
  }

  private func getDownloadLink() -> String {
    if Bundle.main.bundleIdentifier?.contains(".vn") == true {
      return downloadUrlVn
    }
    else {
      return downloadUrl
    }
  }
}

struct SuperSignMaintenanceBean: Codable {
  let endTime: Double?
  let isMaintenance: Bool
}

struct CryptoTutorialBean: Codable {
  let name: String
  let tutorials: [Tutorial]
}

struct Tutorial: Codable {
  let name: String
  let link: String
}

// MARK: - Encode/decode helpers
class JSONNull: Codable, Hashable {
  public static func == (_: JSONNull, _: JSONNull) -> Bool {
    true
  }

  public var hashValue: Int {
    0
  }

  public init() { }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if !container.decodeNil() {
      throw DecodingError.typeMismatch(
        JSONNull.self,
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encodeNil()
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(0)
  }
}
