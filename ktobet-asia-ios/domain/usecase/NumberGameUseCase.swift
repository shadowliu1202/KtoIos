import Foundation
import SharedBu
import RxCocoa
import RxSwift

protocol NumberGameUseCase {
    func getGameTags() -> Single<[GameTag]>
    func getPopularGames() -> Observable<[NumberGame]>
    func addFavorite(game: NumberGame) -> Completable
    func removeFavorite(game: NumberGame) -> Completable
    func getFavorites() -> Single<[NumberGame]>
    func getSuggestionKeywords() -> Single<[String]>
    func searchGames(keyword: SearchKeyword) -> Observable<[NumberGame]>
    func getGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]>
    func createGame(gameId: Int32) -> Single<URL?>
}

class NumberGameUseCasaImp: NumberGameUseCase {
    var numberGameRepository: NumberGameRepository!
    var localRepository: LocalStorageRepository!
    
    var randomPopularNumberGames = BehaviorRelay<[NumberGame]>(value: [])
    let SELECT_GAME_AMOUNT = 2
    let REQUEST_GAME_AMOUNT = 10
    
    init(_ numberGameRepository : NumberGameRepository, _ localRepository: LocalStorageRepository) {
        self.numberGameRepository = numberGameRepository
        self.localRepository = localRepository
    }
    
    func getGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]> {
        return numberGameRepository.searchGames(order: order, tags: tags)
    }
    
    func getGameTags() -> Single<[GameTag]> {
        return numberGameRepository.getTags().map { (tags: [GameTag]) -> [GameTag] in
            tags.sorted(by: { $0.type < $1.type })
        }
    }
    
    func getPopularGames() -> Observable<[NumberGame]> {
        return numberGameRepository.getPopularGames().scan([NumberGame](), accumulator: { (list, hotGames) -> [NumberGame] in
            if list.isEmpty {
                return self.shuffleAndFilterGames(hotNumberGames: hotGames)
            } else {
                return self.updateHotGames(oldGames: list, newGames: hotGames.betCountRanking + hotGames.winLossRanking)
            }
        }).do(onNext: {[weak self] (slotGames) in
            self?.randomPopularNumberGames.accept(slotGames)
        })
    }
    
    private func shuffleAndFilterGames(hotNumberGames: HotNumberGames) -> [NumberGame] {
        let randomMostWinningGames = Array(hotNumberGames.betCountRanking.prefix(REQUEST_GAME_AMOUNT).shuffled().prefix(SELECT_GAME_AMOUNT))
        let randomMostTransactionGames = filterExistedGames(source: hotNumberGames.winLossRanking, existing: randomMostWinningGames).prefix(REQUEST_GAME_AMOUNT)
        return Array(filterExistedGames(source: Array(randomMostTransactionGames), existing: Array(randomMostWinningGames)).prefix(SELECT_GAME_AMOUNT)) + randomMostWinningGames
    }
    
    private func filterExistedGames(source: [NumberGame], existing: [NumberGame]) -> [NumberGame] {
        return source.filter{ !existing.contains($0) }
    }
    
    private func updateHotGames(oldGames: [NumberGame], newGames: [NumberGame]) -> [NumberGame] {
        var newGamesState: [NumberGame] = []
        oldGames.forEach { (oldGame) in
            if let updateFavoriteGame = newGames.first(where: { $0.gameId == oldGame.gameId }) {
                newGamesState.append(updateFavoriteGame)
            }
        }
        
        return newGamesState
    }
    
    func addFavorite(game: NumberGame) -> Completable {
        return numberGameRepository.addFavorite(game: game)
    }
    
    func removeFavorite(game: NumberGame) -> Completable {
        return numberGameRepository.removeFavorite(game: game)
    }
    
    func getFavorites() -> Single<[NumberGame]> {
        return numberGameRepository.getFavorites()
    }
    
    func getSuggestionKeywords() -> Single<[String]> {
        return numberGameRepository.getKeywordSuggestion()
    }
    
    func searchGames(keyword: SearchKeyword) -> Observable<[NumberGame]> {
        if keyword.isSearchPermitted() {
            return numberGameRepository.searchGames(keyword: keyword)
        }
        return Observable.just([])
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return numberGameRepository.createGame(gameId: gameId)
    }
}
