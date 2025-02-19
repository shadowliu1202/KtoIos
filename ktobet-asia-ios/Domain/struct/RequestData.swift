import Foundation
import sharedbu

struct LoginRequest: Encodable {
  var account: String
  var password: String
  var captcha: String
}

struct IRegisterRequest: Encodable {
  var account: String?
  var accountType: Int?
  var currencyCode: String?
  var password: String?
  var realName: String?
}

struct IVerifyOtpRequest: Encodable {
  var verifyCode: String?
}

struct IResetPasswordRequest: Encodable {
  var account: String?
  var accountType: Int?
}

struct INewPasswordRequest: Encodable {
  var newPassword: String?
}

struct RequestVerifyPassword: Encodable {
  var password: String
}

struct RequestResetPassword: Encodable {
  var password: String
}

struct RequestSetRealName: Encodable {
  var realName: String
}

struct RequestChangeBirthDay: Encodable {
  var birthday: String
}

struct DepositOfflineRequestBeanCodable: Codable {
  let paymentTokenID, requestAmount, remitterAccountNumber, remitter: String
  let remitterBankName: String
  let channel, depositType: Int32

  enum CodingKeys: String, CodingKey {
    case paymentTokenID = "paymentTokenId"
    case requestAmount, remitterAccountNumber, remitter, remitterBankName, channel, depositType
  }
}

struct OnlineDepositRequestBeanCodable: Codable {
  let paymentTokenID, requestAmount, remitter: String
  let channel: Int32
  let remitterAccountNumber: String?
  let remitterBankName: String
  let depositType: Int32
  let providerId: Int32
  let bankCode: String

  enum CodingKeys: String, CodingKey {
    case paymentTokenID = "paymentTokenId"
    case requestAmount, remitter, channel, remitterAccountNumber, remitterBankName, depositType, providerId, bankCode
  }
}

struct WithdrawalCancelRequestBeanCodable: Codable {
  let ticketId: String
}

struct WithdrawalBankCardRequestBeanCodable: Codable {
  let requestAmount: Double
  let playerBankCardId: String
}

struct WithdrawalImagesCodable: Codable {
  let ticketStatus: Int32
  let images: [ImageBeanCodable]
}

struct BankCardBeanCodable: Codable {
  let bankID: Int32
  let bankName, branch, accountName, accountNumber, address, city, location: String

  enum CodingKeys: String, CodingKey {
    case bankID = "bankId"
    case bankName, branch, accountName, accountNumber, address, city, location
  }
}

// MARK: - Image
struct ImageBeanCodable: Codable {
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

struct CryptoBankCardRequestCodable: Codable {
  var cryptoCurrency: Int32
  var cryptoWalletName: String
  var cryptoWalletAddress: String
  var cryptoNetwork: Int32
}

struct AccountVerifyRequestCodable: Codable {
  var playerCryptoBankCardId: String
  var accountType: Int
}

struct OTPVerifyRequestCodable: Codable {
  var verifyCode: String
  var accountType: Int
}

struct CryptoWithdrawalRequestCodable: Codable {
  let playerCryptoBankCardId: String
  let requestCryptoAmount, requestFiatAmount: Double
  let cryptoCurrency: Int32

  enum CodingKeys: String, CodingKey {
    case playerCryptoBankCardId
    case requestFiatAmount
    case cryptoCurrency
    case requestCryptoAmount
  }
}

struct PromotionHistoryRequest: Codable {
  var begin: String
  var end: String
  var page: Int
  var productType: [Int32]
  var query: String
  var selected: String
  var type: [Int32]
}

struct BonusRequest: Codable {
  let autoUse: Bool
  let no: String
  let type: Int32
}

struct SendBean: Codable {
  let message: Message
  let roomId: String
}

struct CreateSurveyRequest: Codable {
  let csSkillID: String
  let surveyType, version: Int32
  let surveyAnswers: [SurveyAnswerBean]
  let roomID: String?

  enum CodingKeys: String, CodingKey {
    case csSkillID = "csSkillId"
    case surveyType, version, surveyAnswers
    case roomID = "roomId"
  }
}

struct SurveyAnswerBean: Codable {
  let questionID, questionText: String
  let answer: [AnswerBean?]

  enum CodingKeys: String, CodingKey {
    case questionID = "questionId"
    case questionText, answer
  }
}

struct AnswerBean: Codable {
  let answerID: String?
  let answerText: String
  let isOther: Bool

  enum CodingKeys: String, CodingKey {
    case answerID = "answerId"
    case answerText, isOther
  }
}

struct CustomerMessageData: Codable {
  let content: String
  let email: String
  var title = "Offline Survey"
}

struct DeleteCsRecordsCodable: Codable {
  let roomIds: [String]
  let isExclude: Bool
}

struct CryptoDepositRequestBeanCodable: Codable {
  let cryptoCurrency: Int32
}

struct RequestVerifyOtp: Codable {
  let verifyCode: String
  let bindProfileType: Int
  let isOldProfile: Bool
}

struct RequestChangeIdentity: Codable {
  let account: String
  let bindProfileType: Int
}
