import SharedBu
import UIKit

extension CasinoLobbyType {
    var img: UIImage? {
        switch self {
        case .none:     return nil
        case .platinum: return UIImage(named: "lobby-platinum")
        case .emerald:  return UIImage(named: "lobby-emerald")
        case .virtual_: return UIImage(named: "lobby-virtual")
        default:        return nil
        }
    }
}
