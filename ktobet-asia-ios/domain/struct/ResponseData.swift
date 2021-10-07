//
//  LoginData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/10.
//

import Foundation
import SharedBu


struct ResponseData<T:Codable> : Codable {
    var statusCode : String
    var errorMsg : String
    var node : String?
    var data : T?
}

struct NonNullResponseData<T:Codable> : Codable {
    var statusCode: String
    var errorMsg: String?
    var node: String
    var data: T
}

struct ResponseDataList<T:Codable> : Codable {
    var statusCode : String
    var errorMsg : String
    var node : String?
    var data : [T]
}

struct ResponseDataMap<T:Codable> : Codable {
    var statusCode : String
    var errorMsg : String
    var node : String?
    var data : [String: T]
}

struct ResponseDataPage<T: Codable> : Codable {
    var data: [T]
    var totalCount: Int
}

struct PayloadPage<T: Codable> : Codable {
    var payload: [T]
    var totalCount: Int
}

struct PromotionHistoryBean: Codable {
    var payload: [PromotionPayload]
    var summary: Double
    var totalCount: Int
    
    func convertToPromotions() -> CouponHistorySummary {
        CouponHistorySummary(summary: CashAmount(amount: self.summary), totalCoupon: self.totalCount,
                             couponHistory: self.payload.map({ (p) -> CouponHistory in
                                CouponHistory(amount: CashAmount(amount: p.coupon.amount),
                                              bonusLockReceivingStatus: BonusReceivingStatus.values().get(index: p.coupon.bonusLockStatus)!,
                                              promotionId: p.coupon.id,
                                              name: p.coupon.name,
                                              bonusId: p.coupon.no,
                                              type: BonusType.convert(p.coupon.type),
                                              receiveDate: p.coupon.updatedDate.toLocalDateTime(),
                                              issue: KotlinInt.init(int: p.coupon.issue),
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
            achieved: CashAmount(amount: self.achieved),
            amount: CashAmount(amount: self.amount),
            balance: CashAmount(amount: self.balance),
            formula: self.formula,
            percentage: Percentage(percent: self.percentage.doubleValue()),
            request: CashAmount(amount: self.request),
            turnoverRequest: CashAmount(amount: self.turnoverRequest),
            turnoverRequestForDeposit: CashAmount(amount: self.turnoverRequestForDeposit))
    }
}

struct ILoginData : Codable {
    var phase : Int
    var isLocked : Bool
    var status : Int
}

struct SkillData : Codable {
    var skillId : String
}

struct IPlayer : Codable{
    var displayId: String
    var exp: Double
    var gameId: String
    var isAutoUseCoupon: Bool
    var level: Int
    var realName: String
}

struct ILocalizationData : Codable {
    var cultureCode: String
    var data: [String: String]
}

struct OtpStatus : Codable {
    var isMailActive:Bool
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

struct FullBankAccount {
    var bank: Bank?
    var bankAccount: BankAccount
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
    
    enum CodingKeys: String, CodingKey {
        case depositTypeID = "depositTypeId"
        case depositTypeName
        case depositMethodID = "depositMethodId"
        case displayName, isFavorite
        case paymentTokenID = "paymentTokenId"
        case depositLimitMaximum, depositLimitMinimum
        case specialDisplayType, providerId
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

struct DepositRecordDetailData: Codable {
    let displayID: String
    let requestAmount: Double
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
    
    enum CodingKeys: String, CodingKey {
        case displayID = "displayId"
        case requestAmount, createdDate, updatedDate, status, statusChangeHistories, isPendingHold, ticketType, fee, actualAmount, actualCryptoAmount, actualRate, actualFiatAmount, actualRateDate, hashId, requestRate, requestRateDate, toAddress, requestCryptoAmount
    }
    
    func toDepositDetail(statusChangeHistories: [Transaction.StatusChangeHistory]) -> DepositDetail {
        let createDate = self.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = self.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        let actualRateDate = self.actualRateDate?.convertDateTime() ?? Date()
        let actualRateOffsetDateTime = actualRateDate.convertDateToOffsetDateTime()
        let requestRateDate = self.requestRateDate?.convertDateTime() ?? Date()
        let requestRateOffsetDateTime = requestRateDate.convertDateToOffsetDateTime()
        
        switch TransactionType.Companion.init().convertTransactionType(transactionType_: self.ticketType) {
        case TransactionType.deposit,
             TransactionType.a2ptransferin,
             TransactionType.p2ptransferin:
            return DepositDetail.General.init(
                createdDate: createOffsetDateTime,
                displayId: self.displayID,
                fee: CashAmount(amount: self.fee ?? 0),
                isPendingHold: self.isPendingHold,
                requestAmount: CashAmount(amount: self.requestAmount),
                status: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: self.status),
                statusChangeHistories: statusChangeHistories,
                ticketType: TransactionType.Companion.init().convertTransactionType(transactionType_: self.ticketType),
                updatedDate: updateOffsetDateTime)
        case TransactionType.cryptodeposit:
            let actualCryptoAmount = CryptoExchangeReceipt.init(
                cryptoAmount: CryptoAmount.Companion.init().create(cryptoAmount: self.actualCryptoAmount ?? 0, crypto: .Ethereum()),
                exchangeRate: CryptoExchangeRate.create(crypto: .Ethereum(), rate: self.actualRate ?? 0),
                cashAmount: CashAmount(amount: self.actualFiatAmount ?? 0))
            
            let requestCryptoAmount = CryptoExchangeReceipt.init(
                cryptoAmount: CryptoAmount.Companion.init().create(cryptoAmount: self.requestCryptoAmount ?? 0, crypto: .Ethereum()),
                exchangeRate: CryptoExchangeRate.create(crypto: .Ethereum(), rate: self.requestRate ?? 0),
                cashAmount: CashAmount(amount: self.requestAmount))
            
            return DepositDetail.Crypto.init(
                actualCryptoAmount: actualCryptoAmount,
                actualAmount: CashAmount(amount: self.actualAmount ?? 0),
                actualRateDate: actualRateOffsetDateTime,
                createdDate: createOffsetDateTime,
                displayId: self.displayID,
                fee: CashAmount(amount: self.fee ?? 0),
                hashId: self.hashId ?? "",
                isPendingHold: self.isPendingHold,
                requestCryptoAmount: requestCryptoAmount,
                requestRateDate: requestRateOffsetDateTime,
                status: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: self.status),
                statusChangeHistories: statusChangeHistories,
                ticketType: TransactionType.Companion.init().convertTransactionType(transactionType_: self.ticketType),
                toAddress: self.toAddress ?? "",
                updatedDate: updateOffsetDateTime)
        default:
            return DepositDetail.Unknown.init()
        }
    }
}

struct StatusChangeHistory: Codable {
    let remarkLevel1, remarkLevel2, remarkLevel3, createdDate: String
    let imageIDS: [String]
    
    enum CodingKeys: String, CodingKey {
        case remarkLevel1, remarkLevel2, remarkLevel3, createdDate
        case imageIDS = "imageIds"
    }
}

struct DepositRecordAllData: Codable {
    let date: String
    let logs: [DepositRecordData]
}

struct DailyWithdrawalLimits: Codable {
    let withdrawalLimit: Double
    let withdrawalCount: Int32
    let withdrawalDailyLimit: Double
    let withdrawalDailyCount: Int32
}

struct TurnoverData: Codable {
    let achievedAmount, turnoverAmount: Double
    let cryptoWithdrawalRequestInfos: [CryptoWithdrawalRequestInfo]?
}

struct CryptoWithdrawalRequestInfo: Codable {
    let cryptoCurrency: Int32
    let withdrawalRequest: Double
}

struct WithdrawalRecordData: Codable {
    let displayID: String
    let status, ticketType: Int32
    let createdDate: String
    let requestAmount, actualAmount: Double
    let isPendingHold: Bool
    
    enum CodingKeys: String, CodingKey {
        case displayID = "displayId"
        case status, ticketType, createdDate, requestAmount, actualAmount, isPendingHold
    }
}

struct WithdrawalRecordDetailData: Codable {
    let actualAmount: Double?
    let actualCryptoAmount: Double?
    let actualRate: Double?
    let approvedDate: String
    let createdDate: String
    let cryptoCurrency: Int
    let displayId: String
    let hashId: String?
    let isBatched: Bool
    let isPendingHold: Bool
    let playerCryptoAddress: String?
    let providerCryptoAddress: String?
    let requestAmount: Double
    let requestCryptoAmount: Double?
    let requestRate: Double?
    let status: Int32
    let statusChangeHistories: [StatusChangeHistory]
    let ticketType: Int?
    let updatedDate: String
    
    func toWithdrawalDetail(transactionTransactionType: TransactionType, statusChangeHistories: [Transaction.StatusChangeHistory]) -> WithdrawalDetail {
        let createDate = self.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = self.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        
        let withdrawalRecord = WithdrawalRecord.init(
            transactionTransactionType: transactionTransactionType,
            displayId: displayId,
            transactionStatus: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: status),
            createDate: createOffsetDateTime,
            cashAmount: CashAmount(amount: requestAmount),
            isPendingHold: isPendingHold,
            groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
        
        switch transactionTransactionType {
        case .withdrawal,
             .p2atransferout,
             .p2ptransferout:
            return WithdrawalDetail.General.init(record: withdrawalRecord,
                                                 isBatched: isBatched,
                                                 isPendingHold: isPendingHold,
                                                 statusChangeHistories: statusChangeHistories,
                                                 updatedDate: updateOffsetDateTime)
        case .cryptowithdrawal:
            let approvedDate = self.approvedDate.convertDateTime() ?? Date()
            let approvedOffsetDateTime = approvedDate.convertDateToOffsetDateTime()
            let actualCryptoAmount = CryptoExchangeReceipt.init(cryptoAmount: CryptoAmount.Companion.init().create(cryptoAmount: self.actualCryptoAmount ?? 0, crypto: .Ethereum()), exchangeRate: CryptoExchangeRate.create(crypto: .Ethereum(), rate: actualRate ?? 0), cashAmount: CashAmount(amount: self.actualAmount ?? 0))
            
            let requestCryptoAmount = CryptoExchangeReceipt.init(cryptoAmount: CryptoAmount.Companion.init().create(cryptoAmount: self.requestCryptoAmount ?? 0, crypto: .Ethereum()), exchangeRate: CryptoExchangeRate.create(crypto: .Ethereum(), rate: self.requestRate ?? 0), cashAmount: CashAmount(amount: self.requestAmount))
            
            return WithdrawalDetail.Crypto.init(record: withdrawalRecord,
                                                isBatched: isBatched,
                                                isPendingHold: isPendingHold,
                                                statusChangeHistories: statusChangeHistories,
                                                updatedDate: updateOffsetDateTime,
                                                requestCryptoAmount: requestCryptoAmount,
                                                actualCryptoAmount: actualCryptoAmount,
                                                playerCryptoAddress: playerCryptoAddress ?? "",
                                                providerCryptoAddress: providerCryptoAddress ?? "",
                                                approvedDate: approvedOffsetDateTime,
                                                hashId: hashId ?? "")
        default:
            return WithdrawalDetail.Unknown.init()
        }
    }
}

struct WithdrawalRecordAllData: Codable {
    let date: String
    let logs: [WithdrawalRecordData]
}

struct WithdrawalAccountBean: Codable {
    let playerBankCardID: String
    let bankID: Int
    let branch, bankName, accountName, accountNumber: String
    let location, address, city: String
    let verifyStatus: Int
    
    enum CodingKeys: String, CodingKey {
        case playerBankCardID = "playerBankCardId"
        case bankID = "bankId"
        case branch, bankName, accountName, accountNumber, location, address, city, verifyStatus
    }
}

struct SingleWithdrawalLimitsData: Codable {
    let max: Double
    let minimum: Double
}

//MARK: - Casino
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
    let status: Int
    let releaseDate: String?
    
    enum CodingKeys: String, CodingKey {
        case gameID = "gameId"
        case imageID = "imageId"
        case isGameMaintenance, status, name, hasForFun, isFavorite, releaseDate
    }
    
    func toCasinoGame() -> CasinoGame {
        let thumbnail = CasinoThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: self.imageID)
        return CasinoGame(gameId: Int32(self.gameID), gameName: self.name, isFavorite: self.isFavorite, gameStatus: GameStatus.convertToGameStatus(self.isGameMaintenance, self.status), thumbnail: thumbnail, releaseDate: self.releaseDate?.toLocalDate())
    }
}

struct TagBean: Codable {
    let id: Int
    let name: String
    let tagType: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, tagType
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

struct Nothing : Codable{}

struct NumberGameHotBean: Codable {
    let winLoss: [NumberGameBean]
    let betCount: [NumberGameBean]
    
    func toHotNumberGames(portalHost: String) -> HotNumberGames {
        return HotNumberGames(betCountRanking: self.betCount.map{ $0.toNumberGame(portalHost: portalHost) }, winLossRanking: self.winLoss.map{ $0.toNumberGame(portalHost: portalHost) })
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
        return NumberGame(gameId: gameId,
                          gameName: gameName ?? "",
                          isFavorite: isFavorite, gameStatus:  GameStatus.Companion.init().convert(gameMaintenance: self.isMaintenance, status: self.status), thumbnail: NumberGameThumbnail(host: portalHost, imageId: self.imageId))
    }
}

struct SlotHotGamesBean: Codable {
    let winLoss: [SlotGameBean]
    let betCount: [SlotGameBean]
    
    func toSlotHotGames(portalHost: String) -> SlotHotGames {
        return SlotHotGames(mostTransactionRanking: self.betCount.map{ $0.toSlotGame(portalHost: portalHost) }, mostWinningAmountRanking: self.winLoss.map{ $0.toSlotGame(portalHost: portalHost) })
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
        return SlotGame(gameId: self.gameId,
                        gameName: self.name,
                        isFavorite: self.isFavorite,
                        gameStatus: GameStatus.Companion.init().convert(gameMaintenance: self.isGameMaintenance, status: self.status),
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
        return SlotGame(gameId: self.gameId,
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
        
        func toDateSummary() -> DateSummary {
            let createDate = self.betDate.convertDateTime(format:  "yyyy/MM/dd") ?? Date()
            return DateSummary(totalStakes: CashAmount(amount: self.stakes),
                               totalWinLoss: CashAmount(amount: self.winloss),
                               createdDateTime: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()),
                               count: self.count)
        }
    }
}

struct SlotNewAndJackpotBean: Codable {
    let newGame: [SlotGameBean]
    let jackpot: [SlotGameBean]
    
    func toSlotNewAndJackpotGames(portalHost: String) -> SlotNewAndJackpotGames {
        return SlotNewAndJackpotGames(newGame: self.newGame.map{ $0.toSlotGame(portalHost: portalHost) }, jackpotGames: self.jackpot.map{ $0.toSlotGame(portalHost: portalHost) })
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
        self.count = gameList.map({$0.count}).reduce(0, +)
        self.endDate = gameList.max { (a, b) -> Bool in return a.endDate < b.endDate }?.endDate ?? ""
        self.gameId = gameId
        self.gameName = gameList.first?.gameName ?? ""
        self.imageId = gameList.first?.imageId ?? ""
        self.stakes = gameList.map({$0.stakes}).reduce(0, +)
        self.startDate = gameList.min(by: { (a, b) -> Bool in return a.startDate < b.startDate })?.startDate ?? ""
        self.winloss = gameList.map({$0.winloss}).reduce(0, +)
    }
    
    func toSlotGroupedRecord() -> SlotGroupedRecord {
        let thumbnail = SlotThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId)
        let format1 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let format2 = "yyyy-MM-dd'T'HH:mm:ssZ"
        let end = (endDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        let start = (startDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return SlotGroupedRecord(slotThumbnail: thumbnail, endDate: end, gameId: gameId, gameName: gameName, stakes: CashAmount(amount: stakes), startDate: start, winloss: CashAmount(amount: winloss), recordCount: count)
    }
}

struct SlotBetRecordBean: Codable {
    let betId: String
    let betTime: String
    let stakes: Double
    let winLoss: Double
    let hasDetails: Bool
    
    func toSlotBetRecord(_ zoneOffset: Kotlinx_datetimeZoneOffset) -> SlotBetRecord {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return SlotBetRecord(betId: betId, betTime: betLocalTime, stakes: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss), hasDetails: false)
    }
}

struct SlotUnsettledSummaryBean: Codable {
    let betTime: String
    let stakes: Double
    
    func toSlotUnsettledSummary() -> SlotUnsettledSummary {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
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
    
    func toSlotUnsettledRecord() -> SlotUnsettledRecord {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        let thumbnail = SlotThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId)
        return SlotUnsettledRecord(betId: betId, betTime: betLocalTime, gameId: gameId, gameName: gameName, otherId: otherId, stakes: CashAmount(amount: stakes), slotThumbnail: thumbnail)
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
        return NumberGame(gameId: self.gameId, gameName: self.gameName, isFavorite: self.isFavorite, gameStatus: GameStatus.Companion.init().convert(gameMaintenance: self.isMaintenance, status: self.gameStatus), thumbnail: NumberGameThumbnail(host: portalHost, imageId: self.imageId))
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
    
    func toNumberGame() -> NumberGameSummary.Date {
        return NumberGameSummary.Date.init(betDate: self.betDate.toLocalDate(), count: count, stakes: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss))
    }
    
    func toUnSettleNumberGame() -> NumberGameSummary.Date {
        return NumberGameSummary.Date.init(betDate: self.betDate.toLocalDate(), count: count, stakes: CashAmount(amount: stakes), winLoss: nil)
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
        return NumberGameSummary.RecentlyBet.init(wagerId: wagerId, selection: selection, hasDetail: hasDetails, isStrike: isStrike, gameId: gameId, betTypeName: betTypeName, displayId: betId, gameName: gameName, matchMethod: matchNumber, status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss), stakes: CashAmount(amount: betAmount))
    }
    
    static func convertToBetStatus(status: Int, winLoss: Double) -> NumberGameBetDetail.BetStatus {
        switch status {
        case 0:     return NumberGameBetDetail.BetStatusUnsettledPending.init()
        case 1:     return NumberGameBetDetail.BetStatusSettledWinLose(winLoss: CashAmount(amount: winLoss))
        case 2:     return NumberGameBetDetail.BetStatusSettledCancelled.init()
        case 3:     return NumberGameBetDetail.BetStatusSettledVoid.init()
        case 4:     return NumberGameBetDetail.BetStatusUnsettledConfirmed.init()
        case 5:     return NumberGameBetDetail.BetStatusSettledSelfCancelled.init()
        case 6:     return NumberGameBetDetail.BetStatusSettledStrikeCancelled.init()
        default:    return NumberGameBetDetail.BetStatusSettledCancelled.init()
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
    
    func toNumberGameBetDetail() -> NumberGameBetDetail {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return NumberGameBetDetail(displayId: displayId, traceId: betId, gameName: gameName, matchMethod: matchNumber, betContent: selections, betTime: betLocalTime, stakes: CashAmount(amount: stakes), status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss), result: resultNumber)
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
        return NumberGameSummary.Game.init(gameId: gameId, gameName: gameName, thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId), totalRecords: count, betAmount: CashAmount(amount: stakes), winLoss: nil)
    }
    
    func toSettleGameSummary(portalHost: String) -> NumberGameSummary.Game {
        return NumberGameSummary.Game.init(gameId: gameId, gameName: gameName, thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId), totalRecords: count, betAmount: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss))
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
    
    func toUnSettleGameSummary() -> NumberGameSummary.Bet {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return NumberGameSummary.Bet.init(displayId: betId, wagerId: wagerId, time: betLocalTime, betAmount: CashAmount(amount: stakes), winLoss: nil, hasDetail: hasDetails)
    }
    
    func toSettleGameSummary() -> NumberGameSummary.Bet {
        let settleLocalTime = (String(self.settleTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return NumberGameSummary.Bet.init(displayId: betId, wagerId: wagerId, time: settleLocalTime, betAmount: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss), hasDetail: hasDetails)
    }
}

struct CryptoDepositReceipt: Codable {
    var displayId: String
    var url: String
}

struct CryptoDepositUrl: Codable {
    var url: String
}

struct CryptoBankCardBean: Codable {
    var playerCryptoBankCardId: String
    var cryptoCurrency: Int
    var cryptoWalletName: String
    var cryptoWalletAddress: String
    var status: Int
    var verifyStatus: Int32
    var createdUser: String
    var updatedUser: String
    var updatedDate: String
    
    func toCryptoBankCard() -> CryptoBankCard {
        let updateDate = self.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        let bankCard = BankCardObject(id_: playerCryptoBankCardId,
                                      name: cryptoWalletName,
                                      status: createBankCardStatus(index: status),
                                      verifyStatus: PlayerBankCardVerifyStatus.Companion.init().create(status: verifyStatus))
        
        return CryptoBankCard.init(bankCard: bankCard, currency: Crypto.Ethereum(), walletAddress: cryptoWalletAddress, createdUser: createdUser, updatedUser: updatedUser, updatedDate: updateOffsetDateTime)
    }
    
    private func createBankCardStatus(index: Int) -> BankCardStatus {
        switch index {
        case 0:
            return .none
        case 1, 2:
            return .default_
        default:
            return .none
        }
    }
}

class BankCardObject: BankCard {
    var id_: String
    var name: String
    var status: BankCardStatus
    var verifyStatus: PlayerBankCardVerifyStatus
    
    init(id_: String, name: String, status: BankCardStatus, verifyStatus: PlayerBankCardVerifyStatus) {
        self.id_ = id_
        self.name = name
        self.status = status
        self.verifyStatus = verifyStatus
    }
}

struct CryptoWithdrawalTransaction: Codable {
    let cryptoWithdrawalRequestInfos: [CryptoWithdrawalRequestInfo]
    let totalRequestAmount: Double
    let totalAchievedAmount: Double
    let requestTicketDetails, achievedTicketDetails: [TicketDetail]
    
    func toCryptoWithdrawalLimitLog() -> CryptoWithdrawalLimitLog {
        return CryptoWithdrawalLimitLog(totalRequestAmount: CryptoAmount.create(cryptoAmount: totalRequestAmount, crypto: Crypto.Ethereum.init()),
                                        totalAchievedAmount: CryptoAmount.create(cryptoAmount: totalAchievedAmount, crypto: Crypto.Ethereum.init()),
                                        cryptoWithdrawalRequest: cryptoWithdrawalRequestInfos.map({ CryptoAmount.create(cryptoAmount: $0.withdrawalRequest, crypto: Crypto.Ethereum.init()) }),
                                        requestTicketDetails: requestTicketDetails.map({$0.toCryptoWithdrawalLimitTicketDetail()}),
                                        achievedTicketDetails: achievedTicketDetails.map({$0.toCryptoWithdrawalLimitTicketDetail()}))
    }
}

struct TicketDetail: Codable {
    let approvedDate, displayID: String
    let fiatAmount, cryptoAmount: Double
    let cryptoCurrency: Int32
    
    enum CodingKeys: String, CodingKey {
        case approvedDate
        case displayID = "displayId"
        case fiatAmount, cryptoAmount, cryptoCurrency
    }
    
    func toCryptoWithdrawalLimitTicketDetail() -> CryptoWithdrawalLimitTicketDetail {
        let localApprovedDate = approvedDate.convertDateTime()?.convertDateToOffsetDateTime() ?? Date().convertDateToOffsetDateTime()
        return CryptoWithdrawalLimitTicketDetail(
            cryptoAmount: CryptoAmount.create(cryptoAmount: cryptoAmount, crypto: Crypto.Ethereum.init()),
            approvedDate: localApprovedDate,
            displayId: displayID,
            fiatAmount:CashAmount(amount: fiatAmount)
        )
    }
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
    
    func toTurnOverReceipt() -> P2PTurnOver.TurnOverReceipt {
        let informPlayerDate = self.informPlayerDate.convertDateTime() ?? Date()
        let informPlayerLocalDate =  Kotlinx_datetimeLocalDate.init(year: informPlayerDate.getYear(), monthNumber: informPlayerDate.getMonth(), dayOfMonth: informPlayerDate.getDayOfMonth())
        let parameter = toTurnOverDetailParameters(parameters)
        
        return P2PTurnOver.TurnOverReceipt.init(turnOverDetail: TurnOverDetail.init(achieved: CashAmount(amount: achieved.currencyAmountToDouble() ?? 0), formula: formula, informPlayerDate: informPlayerLocalDate, name: name, bonusId: no, remainAmount: CashAmount(amount: remainingAmount.currencyAmountToDouble() ?? 0), parameters: parameter))
    }
    func toTurnOverDetail() -> TurnOverDetail {
        return TurnOverDetail(achieved: CashAmount(amount: achieved.currencyAmountToDouble() ?? 0), formula: formula, informPlayerDate: self.informPlayerDate.toLocalDate(), name: self.name, bonusId: self.no, remainAmount: CashAmount(amount: self.remainingAmount.currencyAmountToDouble() ?? 0), parameters: self.toTurnOverDetailParameters(self.parameters))
    }
    private func toTurnOverDetailParameters(_ params: Parameters) -> TurnOverDetail.Parameters {
        return TurnOverDetail.Parameters(amount: CashAmount(amount: parameters.amount.currencyAmountToDouble() ?? 0), balance: CashAmount(amount: parameters.balance.currencyAmountToDouble() ?? 0), betMultiplier: Int32(parameters.betMultiplier), capital: CashAmount(amount: parameters.capital.currencyAmountToDouble() ?? 0), depositRequest: CashAmount(amount: parameters.depositRequest.currencyAmountToDouble() ?? 0), percentage: Percentage(percent: parameters.percentage.currencyAmountToDouble() ?? 0), request: CashAmount(amount: parameters.request.currencyAmountToDouble() ?? 0), requirement: CashAmount(amount: parameters.requirement.currencyAmountToDouble() ?? 0), turnoverRequest: CashAmount(amount: parameters.turnoverRequest.currencyAmountToDouble() ?? 0))
    }
}

struct Parameters: Codable {
    let amount: String
    let balance: String
    var betMultiplier: Int {return _betMultiplier ?? 0}
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
    
    func toDateSummary() -> DateSummary {
        let createDate = self.betDate.convertDateTime(format:  "yyyy/MM/dd") ?? Date()
        return DateSummary(totalStakes: CashAmount(amount: self.stakes),
                           totalWinLoss: CashAmount(amount: self.winLoss),
                           createdDateTime: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()),
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
        self.count = gameList.map({$0.count}).reduce(0, +)
        self.endDate = gameList.max { (a, b) -> Bool in return a.endDate < b.endDate }?.endDate ?? ""
        self.gameGroupId = gameGroupId
        self.gameName = gameList.first?.gameName ?? ""
        self.stakes = gameList.map({$0.stakes}).reduce(0, +)
        self.startDate = gameList.min(by: { (a, b) -> Bool in return a.startDate < b.startDate })?.startDate ?? ""
        self.winLoss = gameList.map({$0.winLoss}).reduce(0, +)
        self.imageId = gameList.first?.imageId ?? ""
    }
    
    func toGameGroupedRecord() -> GameGroupedRecord {
        let thumbnail = P2PThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId)
        let format1 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let format2 = "yyyy-MM-dd'T'HH:mm:ssZ"
        let start = (startDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        let end = (endDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return GameGroupedRecord(gameId: gameGroupId, gameName: gameName, thumbnail: thumbnail, recordsCount: count, stakes: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss), startDate: start, endDate: end)
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
        self.count = gameList.map({$0.count}).reduce(0, +)
        self.endDate = gameList.max { (a, b) -> Bool in return a.endDate < b.endDate }?.endDate ?? ""
        self.gameId = gameId
        self.gameName = gameList.first?.gameName ?? ""
        self.stakes = gameList.map({$0.stakes}).reduce(0, +)
        self.startDate = gameList.min(by: { (a, b) -> Bool in return a.startDate < b.startDate })?.startDate ?? ""
        self.winLoss = gameList.map({$0.winLoss}).reduce(0, +)
        self.imageId = gameList.first?.imageId ?? ""
    }
    
    func toGameGroupedRecord() -> GameGroupedRecord {
        let thumbnail = P2PThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId)
        let format1 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let format2 = "yyyy-MM-dd'T'HH:mm:ssZ"
        let start = (startDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        let end = (endDate.convertOffsetDateTime(format1: format1, format2: format2) ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return GameGroupedRecord(gameId: gameId, gameName: gameName, thumbnail: thumbnail, recordsCount: count, stakes: CashAmount(amount: stakes), winLoss: CashAmount(amount: winLoss), startDate: start, endDate: end)
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
    
    func toP2PGameBetRecord() -> P2PGameBetRecord {
        let betLocalTime = (String(self.betTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss", timeZone: "UTC") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return P2PGameBetRecord(betTime: betLocalTime, gameGroupId: gameGroupId, gameName: gameName, groupId: groupId, hasDetails: hasDetails, prededuct: CashAmount(amount: prededuct), stakes: CashAmount(amount: stakes), wagerId: wagerId, winLoss: CashAmount(amount: winLoss))
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
    
    func toArcadeGameBetRecord() -> ArcadeGameBetRecord {
        let betLocalTime = self.betTime.convertDateTime()?.convertDateToOffsetDateTime() ?? Date().convertDateToOffsetDateTime()
        let settleLocalTime = self.settleTime.convertDateTime()?.convertDateToOffsetDateTime() ?? Date().convertDateToOffsetDateTime()
        return ArcadeGameBetRecord(wagerId: self.wagerId, betId: self.betId, betTime: betLocalTime, settleTime: settleLocalTime, hasDetails: self.hasDetails, stakes: CashAmount(amount: self.stakes), winLoss: CashAmount(amount: self.winLoss))
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
    
    func toArcadeGame() -> ArcadeGame{
        return ArcadeGame(gameId: gameId, gameName: name, isFavorite: isFavorite, gameStatus: GameStatus.Companion.init().convert(gameMaintenance: self.isMaintenance, status: self.status), thumbnail: ArcadeThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId))
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
    let amount: Double
    let away: String
    let betMultiple: Int32
    let bonusCouponStatus: Int
    let displayId: String
    let effectiveDate: String
    let expiryDate: String
    let home: String
    let informPlayerDate: String
    let issue: Int32
    let league: String
    let level: Int32
    let maxAmount: Double
    let minCapital: Double
    let name: String
    let no: String
    let percentage: Double
    let productType: Int32
    let fixTurnoverRequirement: Double
    let type: Int32
    let updatedDate: String
    
    var couponStatus: CouponStatus {
        return self.covertBonusPromotionStatus(self.bonusCouponStatus)
    }
    var knAmount: CashAmount {
        return CashAmount(amount: self.amount)
    }
    var knMaxAmount: CashAmount {
        return CashAmount(amount: self.maxAmount)
    }
    var knMinCapital: CashAmount {
        return CashAmount(amount: self.minCapital)
    }
    var knPercentage: Percentage {
        return Percentage(percent: self.percentage)
    }
    
    private func covertBonusPromotionStatus(_ bonusCouponStatus: Int) -> CouponStatus {
        switch bonusCouponStatus {
        case 0:     return CouponStatus.usable
        case 1:     return CouponStatus.used
        case 2:     return CouponStatus.expired
        case 3:     return CouponStatus.full
        default:    return CouponStatus.unknown
        }
    }
    
    func toBonusCoupon() -> BonusCoupon {
        switch self.type {
        case 1:
            return self.toFreebet()
        case 2:
            return self.toDepositReturnCustomize()
        case 3:
            return self.toProduct()
        case 4:
            return self.toRebate()
        case 5:
            return self.toDepositReturnLevel()
        default:
            return BonusCoupon.Other.init()
        }
    }
    
    private func toFreebet() -> BonusCoupon {
        return BonusCoupon.FreeBet.init(promotionId: self.displayId,
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
                                        validPeriod: ValidPeriod.Companion.init().create(start: self.effectiveDate.toOffsetDateTime(),
                                                                                         end: self.expiryDate.toOffsetDateTime()),
                                        minCapital: self.knMinCapital)
    }
    
    private func toDepositReturnCustomize() -> BonusCoupon {
        return BonusCoupon.DepositReturnCustomize(property: self.toDepositReturnProperty())
    }
    
    private func toProduct() -> BonusCoupon {
        return BonusCoupon.Product(promotionId: self.displayId,
                                   bonusId: self.no,
                                   issueNumber: self.issue,
                                   productType: ProductType.convert(self.productType),
                                   informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
                                   maxAmount: self.knMaxAmount,
                                   endDate: self.effectiveDate.toLocalDateTime(),
                                   name: self.name,
                                   betMultiple: self.betMultiple,
                                   fixTurnoverRequirement: self.fixTurnoverRequirement,
                                   validPeriod: ValidPeriod.Companion.init().create(start: self.effectiveDate.toOffsetDateTime(),
                                                                                    end: self.expiryDate.toOffsetDateTime()),
                                   updatedDate: self.updatedDate.toLocalDateTime(),
                                   couponStatus: self.couponStatus,
                                   minCapital: self.knMinCapital)
    }
    
    private func toRebate() -> BonusCoupon {
        return BonusCoupon.Rebate(promotionId: self.displayId,
                                  bonusId: self.no,
                                  rebateFrom: ProductType.convert(self.productType),
                                  name: self.name,
                                  issueNumber: self.issue == 0 ? nil : KotlinInt(value: self.issue),
                                  percentage: self.knPercentage,
                                  amount: self.knAmount,
                                  endDate: self.effectiveDate.toLocalDateTime(),
                                  betMultiple: self.betMultiple,
                                  fixTurnoverRequirement: self.fixTurnoverRequirement,
                                  validPeriod: ValidPeriod.Companion.init().create(start: self.effectiveDate.toOffsetDateTime(),
                                                                                   end: self.expiryDate.toOffsetDateTime()),
                                  couponStatus: self.couponStatus,
                                  updatedDate: self.updatedDate.toLocalDateTime(),
                                  informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
                                  minCapital: self.knMinCapital)
    }
    
    private func toDepositReturnLevel() -> BonusCoupon {
        return BonusCoupon.DepositReturnLevel(level: self.level, property: self.toDepositReturnProperty())
    }
    
    private func toDepositReturnProperty() -> BonusCoupon.DepositReturnProperty {
        return BonusCoupon.DepositReturnProperty(promotionId: self.displayId,
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
                                                 validPeriod:  ValidPeriod.Companion.init().create(start: self.effectiveDate.toOffsetDateTime(),
                                                                                                   end: self.expiryDate.toOffsetDateTime()),
                                                 minCapital: self.knMinCapital)
    }
}

struct PromotionBean: Codable {
    let informPlayerDate: String
    let displayId: String
    let endDate: String
    let isAutoUse: Bool
    let issue: Int32
    let maxAmount: Double
    let name: String?
    let percentage: Double
    let productType: Int32
    
    func toRebatePromotion() -> PromotionEvent.Rebate {
        return PromotionEvent.RebateCompanion.init()
            .create(promotionId: self.displayId,
                    issueNumber: self.issue,
                    informPlayerDate: self.informPlayerDate.toLocalDateTime(),
                    type: ProductType.convert(self.productType),
                    percentage: Percentage(percent: self.percentage),
                    maxBonusAmount: CashAmount(amount: self.maxAmount),
                    endDate: self.endDate.toOffsetDateTime(),
                    isAutoUse: self.isAutoUse)
    }
}

struct ProductPromotionBean: Codable {
    let displayId: String
    let endDate: String
    let informPlayerDate: String
    let issue: Int32
    let maxAmount: Double
    let name: String?
    let productType: Int32
    let sort: Int32
    
    func toProductPromotion() -> PromotionEvent.Product {
        return PromotionEvent.ProductCompanion.init()
            .create(promotionId: self.displayId,
                    issueNumber: self.issue,
                    informPlayerDate: self.informPlayerDate.toLocalDateTime(),
                    endDate: self.endDate.toOffsetDateTime(),
                    maxBonusAmount: CashAmount(amount: self.maxAmount),
                    type: ProductType.convert(self.productType))
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
        get {
            if let value = _status {
                return BonusCouponStatus(rawValue: value)
            }
            return nil
        }
    }
    let type: Int32?
    private var _status: Int32?
    
    enum CodingKeys: String, CodingKey {
        case amount, betMultiple, capital, fixTurnoverRequirement, maxAmount, name, no, percentage, playerLevel, productType, type
        case _status = "status"
    }
    
    enum BonusCouponStatus: Int32 {
        case Usable, Used, Expired, Full
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
        
        private func toCashAmount(_ text: String?) -> CashAmount{
            return CashAmount(amount: text?.currencyAmountToDouble() ?? 0)
        }
        
        fileprivate func toTurnOverHintParameters() -> TurnOverHint.Parameters {
            return TurnOverHint.Parameters(amount: toCashAmount(self.amount), balance: toCashAmount(self.balance), betMultiplier: Int32(betMultiplier ?? 0), capital: toCashAmount(self.capital), request: toCashAmount(self.request), requirement: toCashAmount(self.requirement))
        }
    }
    
    func toTurnOverHint() -> TurnOverHint {
        return TurnOverHint(formula: self.formula, parameters: self.parameters.toTurnOverHintParameters())
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
        return PromotionDescriptions(content: self.contentTemplate, rules: self.rulesTemplate)
    }
}

struct BalanceDateLogBean: Codable {
    let date: String
    let logs: [Log]
}

struct Log: Codable {
    let transactionID: String
    let transactionType, productProvider: Int32
    let externalID: String
    let amount: Double
    let previousBalance, afterBalance: Double
    let createdDate: String
    let transactionMode: Int32?
    let subTitle: String?
    let wagerType: Int32
    let ticketType: Int32?
    let wagerID: String?
    let isDetail: Bool
    let bonusType, productType, issueNumber: Int32
    let transactionSubType: Int
    
    enum CodingKeys: String, CodingKey {
        case transactionID = "transactionId"
        case transactionType, productProvider
        case externalID = "externalId"
        case amount, previousBalance, afterBalance, createdDate, transactionMode, subTitle, wagerType, ticketType
        case wagerID = "wagerId"
        case isDetail, bonusType, productType, issueNumber, transactionSubType
    }
    
    
    
    func toBalanceLog(transactionFactory: TransactionFactory) -> TransactionLog {
        let transactionTypes = TransactionTypes.Companion.init().create(type: transactionType)
        let productTypes = ProductType.convert(productType)
        let bonusTypes = BonusType.convert(bonusType)
        let productProviders = ProductProviders.Companion.init().createProductGroup(provider: productProvider)
        let transferType = ticketType != nil ? TransactionType.Companion.init().convertTransactionType(transactionType_: ticketType!) : TransactionType.none
        let transactionAmount = CashAmount(amount: amount)
        let transaction = Transaction(amount: transactionAmount, date: createdDate.toLocalDateTime(), id_: transactionID)
        let wagerType = WagerType.convert(self.wagerType)
        let transactionMode = self.transactionMode != nil ? try! TransactionModes.convert(self.transactionMode!) : TransactionModes.normal
        return transactionFactory.create(transaction: transaction,
                                         transactionTypes: transactionTypes,
                                         productTypes: productTypes,
                                         bonusTypes: bonusTypes,
                                         productProviders: productProviders,
                                         transferType: transferType,
                                         wagerType: wagerType,
                                         issueNumber: issueNumber,
                                         wagerId: wagerID,
                                         externalId: externalID,
                                         subTitle: subTitle,
                                         transactionMode: transactionMode)
    }
    
    class Transaction: ITransaction {
        var amount: CashAmount
        var date: Kotlinx_datetimeLocalDateTime
        var id_: String
        
        init(amount: CashAmount, date: Kotlinx_datetimeLocalDateTime, id_: String) {
            self.amount = amount
            self.date = date
            self.id_ = id_
        }
    }
}

struct IncomeOutcomeBean: Codable {
    var incomeAmount: Double
    var outcomeAmount: Double
}


struct CashLogSummaryBean: Codable {
    var adjustmentAmount: Double
    var afterBalance: Double
    var bonusAmount: Double
    var casinoAmount: Double
    var depositAmount: Double
    var numberGameAmount: Double
    var previousBalance: Double
    var slotAmount: Double
    var sportsbookAmount: Double
    var p2pAmount: Double
    var arcadeAmount: Double
    var totalAmount: Double
    var withdrawalAmount: Double
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
    
    func toBalanceLogDetail(remark: BalanceLogDetailRemark? = nil) -> BalanceLogDetail {
        return BalanceLogDetail(afterBalance: CashAmount(amount: afterBalance), amount: CashAmount(amount: amount), date: createdDate.toLocalDateTime(), wagerMappingId: wagerMappingId ?? externalId, productGroup: ProductProviders.Companion.init().createProductGroup(provider: productProvider), productType: ProductType.convert(productType), transactionType: TransactionTypes.Companion.init().create(type: transactionType), remark: remark ?? BalanceLogDetailRemark.None(), externalId: externalId)
    }
}

struct BalanceLogBonusRemarkBean: Codable {
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
    
    func toBalanceLogDetailRemark() -> BalanceLogDetailRemark {
        return BalanceLogDetailRemark.Bonus(bonusId: no, bonusName: name, bonusType: BonusType.convert(type), issueNumber: issueNumber, productType: ProductType.convert(productType))
    }
}

struct BalanceLogDetailRemarkBean: Codable {
    let betStatus: Int32
    let description: String?
    let displayIds: [String]?
    let gameName: String?
    let isDetail: Bool
    let lobbyName: String?
    let productProvider: Int32
    let productType: Int32
    let wagerId: [String]?
    
    func toBalanceLogDetailRemark() -> BalanceLogDetailRemark {
        if lobbyName.isNullOrEmpty() && displayIds.isNullOrEmpty() && wagerId.isNullOrEmpty() {
            return BalanceLogDetailRemark.None()
        } else {
            var pair: [KotlinPair<NSString, NSString>] = []
            if let displayIds = displayIds, let wagerId = wagerId, displayIds.count == wagerId.count {
                for i in 0..<displayIds.count {
                    pair.append(KotlinPair(first: displayIds[i] as NSString, second: wagerId[i] as NSString))
                }
            }
            return BalanceLogDetailRemark.General(betStatus: BetStatus_.convert(betStatus), lobbyName: lobbyName ?? "", ids: pair)
        }
    }
}
