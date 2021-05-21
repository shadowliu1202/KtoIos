//
//  LoginData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/10.
//

import Foundation
import share_bu


struct ResponseData<T:Codable> : Codable {
    var statusCode : String
    var errorMsg : String
    var node : String?
    var data : T?
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

    enum CodingKeys: String, CodingKey {
        case depositTypeID = "depositTypeId"
        case depositTypeName
        case depositMethodID = "depositMethodId"
        case displayName, isFavorite
        case paymentTokenID = "paymentTokenId"
        case depositLimitMaximum, depositLimitMinimum
        case specialDisplayType
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
    let createdDate, updatedDate: String
    let status: Int32
    let statusChangeHistories: [StatusChangeHistory]
    let isPendingHold: Bool
    let ticketType: Int32
    let fee: Int32?

    enum CodingKeys: String, CodingKey {
        case displayID = "displayId"
        case requestAmount, createdDate, updatedDate, status, statusChangeHistories, isPendingHold, ticketType, fee, actualAmount
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
    let createdDate: String
    let displayId: String
    let isBatched: Bool
    let isPendingHold: Bool
    let requestAmount: Double
    let status: Int32
    let statusChangeHistories: [StatusChangeHistory]
    let updatedDate: String
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
    let status, verifyStatus: Int

    enum CodingKeys: String, CodingKey {
        case playerBankCardID = "playerBankCardId"
        case bankID = "bankId"
        case branch, bankName, accountName, accountNumber, location, address, city, status, verifyStatus
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
