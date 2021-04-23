import share_bu

extension GameSorting {
    static func convertCasinoGameOrder(sortBy: GameSorting) -> Int {
        switch sortBy {
        case .popular:      return 0
        case .gamename:     return 1
        case .releaseddate: return 2
        default:            return 0
        }
    }
}
