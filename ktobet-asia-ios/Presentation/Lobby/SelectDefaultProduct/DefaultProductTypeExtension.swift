import Foundation
import sharedbu

extension DefaultProductType {
  var localizeString: String {
    switch self {
    case .sbk:
      return Localize.string("common_sportsbook")
    case .slot:
      return Localize.string("common_slot")
    case .casino:
      return Localize.string("common_casino")
    case .numberGame:
      return Localize.string("common_keno")
    }
  }
}
