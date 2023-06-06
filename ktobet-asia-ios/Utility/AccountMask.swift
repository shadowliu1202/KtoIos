import Foundation

class AccountMask {
  static func maskAccount(account: String) -> String {
    if getAccountType(account: account) == AccountType.email {
      return maskEmail(account: account)
    }
    else {
      return maskPhone(account: account)
    }
  }

  private static func maskEmail(account: String) -> String {
    let splitEmail = account.split(separator: "@")
    var head = splitEmail[0]
    if head.count > 6 {
      let startIndex = head.index(head.startIndex, offsetBy: 3)
      let endIndex = head.index(head.endIndex, offsetBy: -4)
      let range = startIndex...endIndex
      let count = head.distance(from: range.lowerBound, to: range.upperBound)
      head.replaceSubrange(range, with: String(repeating: "*", count: count + 1))
    }

    if head.count > 3, head.count <= 6 {
      let startIndex = head.index(head.startIndex, offsetBy: 3)
      let endIndex = head.index(head.endIndex, offsetBy: -1)
      let range = startIndex...endIndex
      let count = head.distance(from: range.lowerBound, to: range.upperBound)
      head.replaceSubrange(range, with: String(repeating: "*", count: count + 1))
    }

    head += "@" + splitEmail[1]
    return String(head)
  }

  private static func maskPhone(account: String) -> String {
    var maskedAcoount = account
    let startIndex = maskedAcoount.index(maskedAcoount.startIndex, offsetBy: 3)
    let endIndex = maskedAcoount.index(maskedAcoount.endIndex, offsetBy: -5)
    let range = startIndex...endIndex
    let count = maskedAcoount.distance(from: range.lowerBound, to: range.upperBound)
    maskedAcoount.replaceSubrange(range, with: String(repeating: "*", count: count + 1))
    return maskedAcoount
  }

  private static func getAccountType(account: String) -> AccountType {
    if account.contains("@") {
      return .email
    }
    else {
      return .phone
    }
  }
}
