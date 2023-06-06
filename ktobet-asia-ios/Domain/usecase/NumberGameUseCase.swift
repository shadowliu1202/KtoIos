import Foundation
import RxCocoa
import RxSwift
import SharedBu

protocol NumberGameUseCase: WebGameUseCase {
  func getGameTags() -> Single<[GameTag]>
  func getPopularGames() -> Observable<[NumberGame]>
  func getGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]>
}

class NumberGameUseCasaImp: WebGameUseCaseImpl, NumberGameUseCase {
  private let numberGameRepository: NumberGameRepository
  private let localRepository: LocalStorageRepository

  var randomPopularNumberGames = BehaviorRelay<[NumberGame]>(value: [])
  let SELECT_GAME_AMOUNT = 2
  let REQUEST_GAME_AMOUNT = 10

  init(
    numberGameRepository: NumberGameRepository,
    localRepository: LocalStorageRepository,
    promotionRepository: PromotionRepository)
  {
    self.numberGameRepository = numberGameRepository
    self.localRepository = localRepository
    super.init(webGameRepository: numberGameRepository, promotionRepository: promotionRepository)
  }

  func getGames(order: GameSorting, tags: Set<GameFilter>) -> Observable<[NumberGame]> {
    numberGameRepository.searchGames(order: order, tags: tags)
  }

  func getGameTags() -> Single<[GameTag]> {
    numberGameRepository.getTags().map { (tags: [GameTag]) -> [GameTag] in
      tags.sorted(by: { $0.type < $1.type })
    }
  }

  func getPopularGames() -> Observable<[NumberGame]> {
    numberGameRepository.getPopularGames().scan([NumberGame](), accumulator: { list, hotGames -> [NumberGame] in
      if list.isEmpty {
        return self.shuffleAndFilterGames(hotNumberGames: hotGames)
      }
      else {
        return self.updateHotGames(oldGames: list, newGames: hotGames.betCountRanking + hotGames.winLossRanking)
      }
    }).do(onNext: { [weak self] slotGames in
      self?.randomPopularNumberGames.accept(slotGames)
    })
  }

  private func shuffleAndFilterGames(hotNumberGames: HotNumberGames) -> [NumberGame] {
    let randomMostWinningGames = Array(
      hotNumberGames.betCountRanking.prefix(REQUEST_GAME_AMOUNT).shuffled()
        .prefix(SELECT_GAME_AMOUNT))
    let randomMostTransactionGames = filterExistedGames(
      source: hotNumberGames.winLossRanking,
      existing: randomMostWinningGames).prefix(REQUEST_GAME_AMOUNT)
    return Array(
      filterExistedGames(source: Array(randomMostTransactionGames), existing: Array(randomMostWinningGames))
        .prefix(SELECT_GAME_AMOUNT)) + randomMostWinningGames
  }

  private func filterExistedGames(source: [NumberGame], existing: [NumberGame]) -> [NumberGame] {
    source.filter { !existing.contains($0) }
  }

  private func updateHotGames(oldGames: [NumberGame], newGames: [NumberGame]) -> [NumberGame] {
    var newGamesState: [NumberGame] = []
    oldGames.forEach { oldGame in
      if let updateFavoriteGame = newGames.first(where: { $0.gameId == oldGame.gameId }) {
        newGamesState.append(updateFavoriteGame)
      }
    }

    return newGamesState
  }
}
