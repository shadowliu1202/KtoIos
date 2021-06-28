//
//  RequestData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/16.
//

import Foundation
import SharedBu


struct LoginRequest : Encodable{
    var account : String
    var password : String
    var captcha : String
}

struct IRegisterRequest : Encodable {
    var account: String?
    var accountType: Int?
    var currencyCode: String?
    var password: String?
    var realName: String?
}

struct IVerifyOtpRequest : Encodable {
    var verifyCode: String?
}

struct IResetPasswordRequest : Encodable {
    var account: String?
    var accountType: Int?
}

struct INewPasswordRequest : Encodable {
    var newPassword : String?
}

struct DepositOfflineBankAccountsRequest: Codable {
    let paymentTokenID, requestAmount, remitterAccountNumber, remitter: String
    let remitterBankName: String
    let channel, depositType: Int32

    enum CodingKeys: String, CodingKey {
        case paymentTokenID = "paymentTokenId"
        case requestAmount, remitterAccountNumber, remitter, remitterBankName, channel, depositType
    }
}

struct DepositOnlineAccountsRequest: Codable {
    let paymentTokenID, requestAmount, remitter: String
    let channel: Int
    let remitterAccountNumber, remitterBankName: String
    let depositType: Int32

    enum CodingKeys: String, CodingKey {
        case paymentTokenID = "paymentTokenId"
        case requestAmount, remitter, channel, remitterAccountNumber, remitterBankName, depositType
    }
}

struct WithdrawalCancelRequest: Codable {
    let ticketId: String
}

struct WithdrawalRequest: Codable {
    let requestAmount: Double
    let playerBankCardId: String
}

struct UploadImagesData: Codable {
    let ticketStatus: Int32
    let images: [Image]
}

struct WithdrawalAccountAddRequest: Codable {
    let bankID: Int32
    let bankName, branch, accountName, accountNumber, address, city, location: String

    enum CodingKeys: String, CodingKey {
        case bankID = "bankId"
        case bankName, branch, accountName, accountNumber, address, city, location
    }
}

// MARK: - Image
struct Image: Codable {
    let imageID, fileName: String

    enum CodingKeys: String, CodingKey {
        case imageID = "imageId"
        case fileName
    }
}

struct ChunkImageDetil: Codable {
    var resumableChunkNumber: String
    var resumableChunkSize: String
    var resumableCurrentChunkSize: String
    var resumableTotalSize: String
    var resumableType: String
    var resumableIdentifier: String
    var resumableFilename: String
    var resumableRelativePath: String
    var resumableTotalChunks: String
    var file: Data
}

struct Empty : Encodable {}

struct CryptoBankCardRequest: Codable {
    var cryptoCurrency: Int
    var cryptoWalletName: String
    var cryptoWalletAddress: String
}

struct AccountVerifyRequest: Codable {
    var playerCryptoBankCardId: String
    var accountType: Int
}

struct OTPVerifyRequest: Codable {
    var verifyCode: String
    var accountType: Int
}
