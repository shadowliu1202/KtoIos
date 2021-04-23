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

