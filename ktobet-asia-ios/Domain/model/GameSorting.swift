import sharedbu

extension GameSorting {
    static func convertCasinoGameOrder(sortBy: GameSorting) -> Int {
        switch sortBy {
        case .popular: return 0
        case .gameName: return 1
        case .releasedDate: return 2
        }
    }
}
