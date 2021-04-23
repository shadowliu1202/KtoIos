import share_bu
import UIKit
import Foundation

extension CasinoGame {
    enum GameState {
        case active
        case inactive(String, UIImage)
        case maintenance(String, UIImage)
    }
    var gameState: GameState {
        switch self.gameStatus {
        case .active:
            return .active
        case .inactive:
            return .inactive(Localize.string("product_game_removed"), UIImage(named: "game-off")!)
        case .maintenance:
            return .maintenance(Localize.string("product_under_maintenance"), UIImage(named: "game-maintainance")!)
        default:
            return .active
        }
    }
    
}
