import Foundation
import sharedbu

class EnumMapper {
  static func convert(speakerType: Int32) -> SpeakerType {
    try! EnumMapper.convert(speakerType: speakerType).1
  }

  static func convert(speakerType: SpeakerType) -> Int32 {
    try! EnumMapper.convert(speakerType: speakerType).0
  }

  private static func convert(speakerType: Any) throws -> (Int32, SpeakerType) {
    let dictionary: [Int32: SpeakerType] = [
      0: SpeakerType.player,
      1: SpeakerType.handler,
      2: SpeakerType.system
    ]
    
    switch speakerType {
    case let value as SpeakerType:
      if let id = dictionary.first(where: { $0.value == value })?.key {
        return (id, value)
      }

    case let key as Int32:
      if let value = dictionary[key] {
        return (key, value)
      }
    default: break
    }
    throw KtoException(errorMsg: "Unknown type", errorCode: "")
  }

  static func convert(accountType: Int) -> sharedbu.AccountType {
    try! EnumMapper.convert(accountType: accountType).1
  }

  static func convert(accountType: sharedbu.AccountType) -> Int {
    try! EnumMapper.convert(accountType: accountType).0
  }

  private static func convert(accountType: Any) throws -> (Int, sharedbu.AccountType) {
    let dictionary: [Int: sharedbu.AccountType] = [
      1: sharedbu.AccountType.email,
      2: sharedbu.AccountType.phone
    ]
    switch accountType {
    case let value as sharedbu.AccountType:
      if let id = dictionary.first(where: { $0.value == value })?.key {
        return (id, value)
      }

    case let key as Int:
      if let value = dictionary[key] {
        return (key, value)
      }
    default: break
    }
    throw KtoException(errorMsg: "Unknown type", errorCode: "")
  }
}
