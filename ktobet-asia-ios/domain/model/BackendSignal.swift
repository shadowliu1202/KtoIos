import Foundation

// MARK: - BackendSignal

protocol BackendSignal {
  static func getName(_: Self?) -> String
}

// MARK: - MaintenanceSignal

enum MaintenanceSignal: BackendSignal {
  case all(timeRange: TimeRange?)
  case casino(timeRange: TimeRange?)
  case slot(timeRange: TimeRange?)
  case numberGame(timeRange: TimeRange?)
  case sbk(timeRange: TimeRange?)
  case p2p(timeRange: TimeRange?)
  case arcade(timeRange: TimeRange?)

  static func getName(_ signal: MaintenanceSignal?) -> String {
    guard let signal else {
      return ""
    }

    switch signal {
    case .all:
      return "Maintenance"
    case .casino:
      return "ProductCasinoMaintenance"
    case .slot:
      return "ProductSlotMaintenance"
    case .numberGame:
      return "ProductNumberGameMaintenance"
    case .sbk:
      return "ProductSBKMaintenance"
    case .p2p:
      return "ProductP2pMaintenance"
    case .arcade:
      return "ProductArcadeMaintenance"
    }
  }

  struct TimeRange: Codable {
    let scopeType: Int
    let startTime: String
    let endTime: String
  }
}

extension MaintenanceSignal: CaseIterable {
  static var allCases: [MaintenanceSignal] = [
    .all(timeRange: nil),
    .casino(timeRange: nil),
    .slot(timeRange: nil),
    .numberGame(timeRange: nil),
    .sbk(timeRange: nil),
    .p2p(timeRange: nil),
    .arcade(timeRange: nil)
  ]
}

// MARK: - KickOutSignal

enum KickOutSignal: Int, BackendSignal {
  case duplicatedLogin = 1
  case Suspend = 2
  case Inactive = 3
  case Maintenance = 4
  case TokenExpired = 5

  static func getName(_: KickOutSignal?) -> String {
    "Kickout"
  }
}

// MARK: - BalanceSignal

struct BalanceSignal: BackendSignal {
  static func getName(_: BalanceSignal?) -> String {
    "Balance"
  }
}
