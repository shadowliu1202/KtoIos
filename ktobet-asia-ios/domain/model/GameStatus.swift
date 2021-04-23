import share_bu


extension GameStatus {
    static func convertToGameStatus(_ gameMaintenance: Bool, _ status: Int) -> GameStatus {
        if gameMaintenance {
            return GameStatus.maintenance
        } else if status == 0 {
            return GameStatus.inactive
        } else {
            return GameStatus.active
        }
    }
}
