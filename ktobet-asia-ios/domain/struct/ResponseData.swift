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
        CouponHistorySummary(summary: self.summary.toAccountCurrency(), totalCoupon: self.totalCount,
                             couponHistory: self.payload.map({ (p) -> CouponHistory in
            CouponHistory(amount: p.coupon.amount.toAccountCurrency(),
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
    var amountLimitOptions: [Int32]?
    
    enum CodingKeys: String, CodingKey {
        case depositTypeID = "depositTypeId"
        case depositTypeName
        case depositMethodID = "depositMethodId"
        case displayName, isFavorite
        case paymentTokenID = "paymentTokenId"
        case depositLimitMaximum, depositLimitMinimum
        case specialDisplayType, providerId
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
        case requestAmount, createdDate, updatedDate, status, statusChangeHistories, isPendingHold, ticketType, fee, actualAmount, actualCryptoAmount, actualRate, actualFiatAmount, actualRateDate, hashId, requestRate, requestRateDate, toAddress, requestCryptoAmount, approvedDate, cryptoCurrency
    }
    
    func toDepositDetail(statusChangeHistories: [Transaction.StatusChangeHistory]) -> DepositDetail? {
        let createDate = self.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = self.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        let requestApprovedDate = self.approvedDate?.convertDateTime() ?? Date()
        let requestApprovedOffsetDateTime = requestApprovedDate.convertDateToOffsetDateTime()
        
        let detail = DepositDetail.Flat.init(displayId: self.displayID,
                                             fee: self.fee?.toAccountCurrency() ?? AccountCurrency.zero(),
                                             isPendingHold: self.isPendingHold,
                                             requestAmount: self.requestAmount?.toAccountCurrency() ?? AccountCurrency.zero(),
                                             actualAmount: self.actualAmount?.toAccountCurrency() ?? AccountCurrency.zero(),
                                             status: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: self.status),
                                             statusChangeHistories: statusChangeHistories,
                                             ticketType: TransactionType.Companion.init().convertTransactionType(transactionType_: self.ticketType),
                                             createdDate: createOffsetDateTime,
                                             updatedDate: updateOffsetDateTime,
                                             approvedDate: requestApprovedOffsetDateTime)
        
        switch TransactionType.Companion.init().convertTransactionType(transactionType_: self.ticketType) {
        case .deposit, .a2ptransferin, .p2ptransferin:
            return detail
        case .cryptodeposit:
            return DepositDetail.Crypto(requestTransaction:
                                            createExchangeRecord(flatAmount: self.requestAmount?.toAccountCurrency().amount(),
                                                                 cryptoAmount: String(self.requestCryptoAmount ?? 0),
                                                                 cryptoCurrency: self.cryptoCurrency,
                                                                 rate: String(self.requestRate ?? 0),
                                                                 rateDate: self.requestRateDate)!,
                                             actualTransaction: createExchangeRecord(flatAmount: self.actualAmount?.toAccountCurrency().amount(),
                                                                                     cryptoAmount: String(self.actualCryptoAmount ?? 0),
                                                                                     cryptoCurrency: self.cryptoCurrency,
                                                                                     rate: String(self.actualRate ?? 0),
                                                                                     rateDate: self.actualRateDate),
                                             hashId: self.hashId ?? "",
                                             toAddress: self.toAddress ?? "",
                                             generalDetail: detail)
        default:
            return nil
        }
    }
    
    private func createExchangeRecord(flatAmount: String?, cryptoAmount: String?, cryptoCurrency: Int?, rate: String?, rateDate: String?) -> CryptoExchangeRecord? {
        guard let flatAmount = flatAmount,
              let cryptoAmount = cryptoAmount,
              let supportCryptoType = cryptoCurrency?.toSupportCryptoType(),
              let rate = rate,
              let rateDate = rateDate else { return nil }
        let exchangeRate = CryptoExchangeFactory.init().create(from: supportCryptoType, to: LocalStorageRepository().getSupportLocal(), exRate: rate)
        return CryptoExchangeRecord.init(cryptoAmount: cryptoAmount.toCryptoCurrency(cryptoCurrencyCode: cryptoCurrency),
                                         exchangeRate: exchangeRate,
                                         cashAmount: flatAmount.toAccountCurrency(),
                                         date: rateDate.toOffsetDateTime())
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
        let withdrawalRecord = WithdrawalRecord.init(
            transactionTransactionType: transactionTransactionType,
            displayId: displayId,
            transactionStatus: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: status),
            createDate: self.createdDate.toOffsetDateTime(),
            cashAmount: self.requestAmount.toAccountCurrency(),
            isPendingHold: isPendingHold,
            groupDay: self.createdDate.toLocalDate())
        
        switch transactionTransactionType {
        case .withdrawal,
             .p2atransferout,
             .p2ptransferout:
            return WithdrawalDetail.General.init(record: withdrawalRecord,
                                                 isBatched: isBatched,
                                                 isPendingHold: isPendingHold,
                                                 statusChangeHistories: statusChangeHistories,
                                                 updatedDate: self.updatedDate.toOffsetDateTime())
        case .cryptowithdrawal:
            return WithdrawalDetail.Crypto(record: withdrawalRecord, isBatched: isBatched, isPendingHold: isPendingHold, statusChangeHistories: statusChangeHistories, updatedDate: updatedDate.toOffsetDateTime(), requestCryptoAmount: toCryptoExchangeRecord("\(requestCryptoAmount ?? 0)", cryptoCurrency, "\(requestAmount)", "\(requestRate ?? 0)", createdDate), actualCryptoAmount: toCryptoExchangeRecord("\(actualCryptoAmount ?? 0)", cryptoCurrency, "\(actualAmount ?? 0)", "\(actualRate ?? 0)", createdDate), playerCryptoAddress: playerCryptoAddress ?? "", providerCryptoAddress: providerCryptoAddress ?? "", approvedDate: approvedDate.toOffsetDateTime(), hashId: hashId ?? "")
        default:
            return WithdrawalDetail.Unknown.init()
        }
    }
    
    private func toCryptoExchangeRecord(_ cryptoCurrency: String, _ cryptoCurrencyCode: Int, _ accountCurrency: String, _ exchangeRate: String, _ createdDate: String) -> CryptoExchangeRecord {
         do {
            let crypto = cryptoCurrency.toCryptoCurrency(cryptoCurrencyCode: cryptoCurrencyCode)
            let cryptoType = try SupportCryptoType.companion.typeOf(cryptoCurrency: crypto)
            let exchangeRate = CryptoExchangeFactory.init().create(from: cryptoType, to: LocalStorageRepository().getSupportLocal(), exRate: exchangeRate)
            return CryptoExchangeRecord.init(cryptoAmount: crypto,
                                             exchangeRate: exchangeRate,
                                             cashAmount: accountCurrency.toAccountCurrency(),
                                             date: createdDate.toOffsetDateTime())
         } catch {
             print(error)
             fatalError("SupportCryptoType.companion.typeOf got error = \(error.localizedDescription)")
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
    
    class BankCardModle: BankCard {
        private var bean: WithdrawalAccountBean!
        private var banks: [Int : Bank]!
        private var locale: SupportLocale!
        var id_: String {
            bean.playerBankCardID
        }
        var name: String {
            bean.bankID == 0 ? bean.bankName : createBankName(bankName: bean.bankName, bank: banks[bean.bankID], locale: locale)
        }
        var status: BankCardStatus {
            self.createBankCardStatus(bean.verifyStatus)
        }
        var verifyStatus: PlayerBankCardVerifyStatus {
            PlayerBankCardVerifyStatus.Companion.init().create(status: Int32(bean.verifyStatus))
        }
        
        init(_ bean: WithdrawalAccountBean, _ banks: [Int : Bank], _ locale: SupportLocale) {
            self.bean = bean
            self.banks = banks
            self.locale = locale
        }
        
        func createBankName(bankName: String, bank: Bank?, locale: SupportLocale) -> String {
            bank == nil ? bankName : "(\(bank!.shortName)) \(bankName)"
        }
    }
    
    func toFiatBankCard(banks: [Int : Bank], locale: SupportLocale) -> FiatBankCard {
        return FiatBankCard(bankCard: BankCardModle(self, banks, locale), accountName: accountName, accountNumber: accountNumber, bankId: Int32(bankID), branch: branch, city: city, location: location)
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
            return DateSummary(totalStakes: self.stakes.toAccountCurrency(),
                               totalWinLoss: self.winloss.toAccountCurrency(),
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
        return SlotGroupedRecord(slotThumbnail: thumbnail, endDate: end, gameId: gameId, gameName: gameName, stakes: stakes.toAccountCurrency(), startDate: start, winloss: winloss.toAccountCurrency(), recordCount: count)
    }
}

struct SlotBetRecordBean: Codable {
    let betId: String
    let betTime: String
    let stakes: Double
    let winLoss: Double
    let hasDetails: Bool
    
    func toSlotBetRecord(_ zoneOffset: Kotlinx_datetimeZoneOffset) -> SlotBetRecord {
        let betLocalTime = betTime.toLocalDateTime()
        return SlotBetRecord(betId: betId, betTime: betLocalTime, stakes: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency(), hasDetails: false)
    }
}

struct SlotUnsettledSummaryBean: Codable {
    let betTime: String
    let stakes: Double
    
    func toSlotUnsettledSummary() -> SlotUnsettledSummary {
        let betLocalTime = betTime.toLocalDateTime()
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
        let betLocalTime = betTime.toLocalDateTime()
        let thumbnail = SlotThumbnail(host: KtoURL.baseUrl.absoluteString, thumbnailId: imageId)
        return SlotUnsettledRecord(betId: betId, betTime: betLocalTime, gameId: gameId, gameName: gameName, otherId: otherId, stakes: stakes.toAccountCurrency(), slotThumbnail: thumbnail)
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
        return NumberGameSummary.Date.init(betDate: self.betDate.toLocalDate(), count: count, stakes: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency())
    }
    
    func toUnSettleNumberGame() -> NumberGameSummary.Date {
        return NumberGameSummary.Date.init(betDate: self.betDate.toLocalDate(), count: count, stakes: stakes.toAccountCurrency(), winLoss: nil)
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
        return NumberGameSummary.RecentlyBet.init(wagerId: wagerId, selection: selection, hasDetail: hasDetails, isStrike: isStrike, gameId: gameId, betTypeName: betTypeName, displayId: betId, gameName: gameName, matchMethod: matchNumber, status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss), stakes: betAmount.toAccountCurrency())
    }
    
    static func convertToBetStatus(status: Int, winLoss: Double) -> NumberGameBetDetail.BetStatus {
        switch status {
        case 0:     return NumberGameBetDetail.BetStatusUnsettledPending.init()
        case 1:     return NumberGameBetDetail.BetStatusSettledWinLose(winLoss: winLoss.toAccountCurrency())
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
        let betLocalTime = betTime.toLocalDateTime()
        return NumberGameBetDetail(displayId: displayId, traceId: betId, gameName: gameName, matchMethod: matchNumber, betContent: selections, betTime: betLocalTime, stakes: stakes.toAccountCurrency(), status: RecentlyBet.convertToBetStatus(status: status, winLoss: winLoss), result: resultNumber)
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
        return NumberGameSummary.Game.init(gameId: gameId, gameName: gameName, thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId), totalRecords: count, betAmount: stakes.toAccountCurrency(), winLoss: nil)
    }
    
    func toSettleGameSummary(portalHost: String) -> NumberGameSummary.Game {
        return NumberGameSummary.Game.init(gameId: gameId, gameName: gameName, thumbnail: NumberGameThumbnail(host: portalHost, imageId: imageId), totalRecords: count, betAmount: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency())
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
        let betLocalTime = betTime.toLocalDateTime()
        return NumberGameSummary.Bet.init(displayId: betId, wagerId: wagerId, time: betLocalTime, betAmount: stakes.toAccountCurrency(), winLoss: nil, hasDetail: hasDetails)
    }
    
    func toSettleGameSummary() -> NumberGameSummary.Bet {
        let settleLocalTime = (String(self.settleTime.prefix(19)).convertDateTime(format: "yyyy-MM-dd'T'HH:mm:ss") ?? Date()).convertToKotlinx_datetimeLocalDateTime()
        return NumberGameSummary.Bet.init(displayId: betId, wagerId: wagerId, time: settleLocalTime, betAmount: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency(), hasDetail: hasDetails)
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
    var cryptoNetwork: Int
    
    func toCryptoBankCard() -> CryptoBankCard {
        guard let cryptoType = cryptoCurrency.toSupportCryptoType() else {
            fatalError("cryptoCurrency is not SupportCryptoType")
        }

        let updateDate = (self.updatedDate.convertDateTime() ?? Date()).convertDateToOffsetDateTime()
        let bankCard = BankCardObject(id_: playerCryptoBankCardId,
                                      name: cryptoWalletName,
                                      status: status,
                                      verifyStatus: PlayerBankCardVerifyStatus.Companion.init().create(status: verifyStatus))
        
        return CryptoBankCard(bankCard: bankCard, currency: cryptoType, walletAddress: cryptoWalletAddress, createdUser: createdUser, updatedUser: updatedUser, updatedDate: updateDate, cryptoNetwork: convertTo(cryptoNetwork: cryptoNetwork))
    }
    
    private func convertTo(cryptoNetwork index: Int) -> CryptoNetwork {
        switch index {
        case 1:
            return CryptoNetwork.erc20
        case 2:
            return CryptoNetwork.trc20
        default:
            return CryptoNetwork.erc20
        }
    }
}

class BankCardObject: BankCard {
    var id_: String
    var name: String
    private var _status: Int
    var status: BankCardStatus {
        createBankCardStatus(_status)
    }
    var verifyStatus: PlayerBankCardVerifyStatus
    
    init(id_: String, name: String, status: Int, verifyStatus: PlayerBankCardVerifyStatus) {
        self.id_ = id_
        self.name = name
        self._status = status
        self.verifyStatus = verifyStatus
    }
}

struct CryptoWithdrawalTransaction: Codable {
    let cryptoWithdrawalRequestInfos: [CryptoWithdrawalRequestInfo]
    let totalRequestAmount: Double
    let totalAchievedAmount: Double
    let requestTicketDetails, achievedTicketDetails: [TicketDetail]
    
    func toSummary() -> CpsWithdrawalSummary {
        return CpsWithdrawalSummary(remainTurnOver: sumOfTurnOver(infos: cryptoWithdrawalRequestInfos),
                                    requestTurnOver: toTurnOver(list: requestTicketDetails, amount: totalRequestAmount),
                                    achievedTurnOver: toTurnOver(list: achievedTicketDetails, amount: totalAchievedAmount))
    }

    private func sumOfTurnOver(infos: [CryptoWithdrawalRequestInfo]) -> AccountCurrency {
        return infos.map({$0.withdrawalRequest.toAccountCurrency()}).reduce(AccountCurrency.zero()) { $0+$1 }
    }
    
    private func toTurnOver(list: [TicketDetail], amount: Double) -> CpsWithdrawalSummary.TurnOverTransaction {
        return CpsWithdrawalSummary.TurnOverTransaction(total: amount.toAccountCurrency(), record: list.map({$0.toDetail()}))
    }
    
}

struct TicketDetail: Codable {
    let approvedDate, displayID: String
    let fiatAmount, cryptoAmount: Double
    let cryptoCurrency: Int
    
    enum CodingKeys: String, CodingKey {
        case approvedDate
        case displayID = "displayId"
        case fiatAmount, cryptoAmount, cryptoCurrency
    }
    
    func toDetail() -> CpsWithdrawalSummary.TurnOverDetail {
        CpsWithdrawalSummary.TurnOverDetail(displayId: "\(displayID)", cryptoAmount: cryptoAmount.toCryptoCurrency(cryptoCurrency), approvedDate: approvedDate.toOffsetDateTime(), flatAmount: fiatAmount.toAccountCurrency())
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
        let informPlayerDate = self.informPlayerDate.toOffsetDateTime()
        let parameter = toTurnOverDetailParameters(parameters)
        
        return P2PTurnOver.TurnOverReceipt.init(
            turnOverDetail: TurnOverDetail.init(
                achieved: achieved.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
                formula: formula,
                informPlayerDate: informPlayerDate,
                name: name,
                bonusId: no,
                remainAmount: remainingAmount.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
                parameters: parameter))
    }
    func toTurnOverDetail() -> TurnOverDetail {
        return TurnOverDetail(
            achieved: achieved.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
            formula: formula, informPlayerDate: self.informPlayerDate.toOffsetDateTime(),
            name: self.name,
            bonusId: self.no,
            remainAmount: self.remainingAmount.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency(),
            parameters: self.toTurnOverDetailParameters(self.parameters))
    }
    private func toTurnOverDetailParameters(_ params: Parameters) -> TurnOverDetail.Parameters {
        return TurnOverDetail.Parameters(
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
        return DateSummary(totalStakes: self.stakes.toAccountCurrency(),
                           totalWinLoss: self.winLoss.toAccountCurrency(),
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
        return GameGroupedRecord(gameId: gameGroupId, gameName: gameName, thumbnail: thumbnail, recordsCount: count, stakes: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency(), startDate: start, endDate: end)
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
        return GameGroupedRecord(gameId: gameId, gameName: gameName, thumbnail: thumbnail, recordsCount: count, stakes: stakes.toAccountCurrency(), winLoss: winLoss.toAccountCurrency(), startDate: start, endDate: end)
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
        let betLocalTime = betTime.toLocalDateTime()
        return P2PGameBetRecord(betTime: betLocalTime, gameGroupId: gameGroupId, gameName: gameName, groupId: groupId, hasDetails: hasDetails, prededuct: prededuct.toAccountCurrency(), stakes: stakes.toAccountCurrency(), wagerId: wagerId, winLoss: winLoss.toAccountCurrency())
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
        return ArcadeGameBetRecord(wagerId: self.wagerId, betId: self.betId, betTime: betLocalTime, settleTime: settleLocalTime, hasDetails: self.hasDetails, stakes: self.stakes.toAccountCurrency(), winLoss: self.winLoss.toAccountCurrency())
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
    let bonusCouponStatus: Int32
    let displayId: String
    let effectiveDate: String
    let expiryDate: String
    let home: String
    let informPlayerDate: String
    let isLimitedByDailyFull: Bool?
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
        return self.covertBonusPromotionStatus(self.bonusCouponStatus, isLimitedByDailyFull)
    }
    var knAmount: AccountCurrency {
        return self.amount.toAccountCurrency()
    }
    var knMaxAmount: Promotion.IMaxAmount {
        return Promotion.companion.create(amount: self.maxAmount.toAccountCurrency())
    }
    var knMinCapital: AccountCurrency {
        return  self.minCapital.toAccountCurrency()
    }
    var knPercentage: Percentage {
        return Percentage(percent: self.percentage)
    }
    
    private func covertBonusPromotionStatus(_ bonusCouponStatus: Int32, _ isLimitedByDailyFull: Bool?) -> CouponStatus {
        return CouponStatus.companion.convert(status: bonusCouponStatus, reachedDailyLimit: isLimitedByDailyFull ?? false)
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
                    maxBonusAmount: self.maxAmount.toAccountCurrency(),
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
                    maxBonusAmount: self.maxAmount.toAccountCurrency(),
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
        
        private func toCashAmount(_ text: String?) -> AccountCurrency {
            return text?.currencyAmountToDouble()?.toAccountCurrency() ?? 0.toAccountCurrency()
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
    let transactionSubType: Int32
    
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
        let transactionAmount = amount.toAccountCurrency()
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
                                         transactionMode: transactionMode,
                                         transactionSubType: toTransactionSubType(transactionSubType))
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
    
    func toTransactionSubType(_ i: Int32) -> TransactionSubType {
        for index in 0..<TransactionSubType.values().size {
            if (TransactionSubType.values().get(index: index))!.ordinal == i {
                return TransactionSubType.values().get(index: index) ?? TransactionSubType.none
            }
        }
        return TransactionSubType.none
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
        return BalanceLogDetail(afterBalance: afterBalance.toAccountCurrency(), amount: amount.toAccountCurrency(), date: createdDate.toLocalDateTime(), wagerMappingId: wagerMappingId ?? externalId, productGroup: ProductProviders.Companion.init().createProductGroup(provider: productProvider), productType: ProductType.convert(productType), transactionType: TransactionTypes.Companion.init().create(type: transactionType), remark: remark ?? BalanceLogDetailRemark.None(), externalId: externalId)
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

//struct InProcessResponse: Codable {
//    let messageID: Int32
//    let speaker: String
//    let speakerID: Int?
//    let speakerType: Int32
//    let html, text, createDate: String
//    let messageType: Int32
//    let fileID: String?
//
//    enum CodingKeys: String, CodingKey {
//        case messageID = "messageId"
//        case speaker
//        case speakerID = "speakerId"
//        case speakerType, html, text, createDate, messageType
//        case fileID = "fileId"
//    }
//}

struct PlayerInChatBean: Codable {
    let roomId: String?
    let skillId: String?
    let token: String?
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
        Survey(csSkillId: skillId,
               surveyId: surveyId,
               description: description ?? "",
               surveyType: convertSurveyType(surveyType),
               surveyQuestions: surveyQuestions?.map{ $0.toSurveyQuestion() } ?? [],
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
         switch (surveyType) {
         case 0:    return .prechat
         case 1:    return .exit
         default:   return .unknown
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
        SurveyQuestion_(questionId: questionId,
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
                        surveyQuestionOptions: surveyQuestionOptions.map{ $0.toSurveyQuestionOption() },
                        surveyQuestionType: convert(surveyQuestionType))
    }
    
    func convert(_ surveyQuestionType: Int32) -> SurveyQuestion_.SurveyQuestionType {
        switch surveyQuestionType {
        case 1:         return .simpleoption
        case 2:         return .multipleoption
        case 6:         return .textfield
        default:        fatalError("unknown surveyQuestionType : \(surveyQuestionType)")
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
        SurveyQuestion_.SurveyQuestionOption(optionId: optionId, questionId: questionId, enable: enable, isOther: isOther, values: values)
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

struct ChatHistories: Codable {
    let payload: [Payload]
    let totalCount: Int
    
    struct Payload: Codable {
        let createdDate: String
        let roomId: String
        let title: String?
        
        func toChatHistory() -> ChatHistory {
            return ChatHistory(createDate: createdDate.toLocalDateTime(), title: title ?? "", roomId: roomId)
        }
    }
}

//struct ChatHistoriesBean: Codable {
//    let payload: [Payload]?
//    let totalCount: Int
//
//    struct Payload: Codable {
//        let roomHistories: [RoomHistory]
//        let roomId: String
//        let roomNo: String
//    }
//}

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
    
    func convert() -> SharedBu.Attributes {
        SharedBu.Attributes.init(align: KotlinInt.init(value: Int32(align ?? 0)),
                                 background: background,
                                 bold: KotlinBoolean.init(value: bold ?? false),
                                 color: color,
                                 font: font,
                                 image: image,
                                 italic: KotlinBoolean.init(value: italic ?? false),
                                 link: link,
                                 size: size,
                                 underline: KotlinBoolean.init(value: underline ?? false))
    }
}


struct CryptoCurrencyBean: Codable {
    let cryptoCurrencyInfo: [CryptoCurrencyInfo]
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
    
    func toMaintenanceStatus() -> MaintenanceStatus {
        MaintenanceStatus.Product(productsAvailable: productsAvailable.map{ ProductType.convert($0) },
                                  status: [ProductType.numbergame: numberGameMaintenanceEndTime?.toOffsetDateTime(),
                                           ProductType.sbk: sbkMaintenanceEndTime?.toOffsetDateTime(),
                                           ProductType.slot: slotMaintenanceEndTime?.toOffsetDateTime(),
                                           ProductType.casino: casinoMaintenanceEndTime?.toOffsetDateTime(),
                                           ProductType.p2p: p2pMaintenanceEndTime?.toOffsetDateTime(),
                                           ProductType.arcade: arcadeMaintenanceEndTime?.toOffsetDateTime()])
    }
}

struct VersionData: Codable {
    let ipaCapacity: String
    let ipaVersion: String
    let ipaVersionHash: String
    let downloadUrl: String
    
    func toVersion() -> Version {
        Version.companion.create(version: ipaVersion, link: downloadUrl, size: ipaCapacity.doubleValue())
    }
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

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
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
