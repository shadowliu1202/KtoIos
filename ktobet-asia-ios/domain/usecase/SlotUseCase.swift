import Foundation
import SharedBu
import RxSwift
import RxCocoa

protocol SlotUseCase: WebGameUseCase {
    func getPopularSlots() -> Observable<[SlotGame]>
    func getRecentlyPlaySlots() -> Observable<[SlotGame]>
    func getNewSlots() -> Observable<[SlotGame]>
    func getJackpotSlots() -> Observable<[SlotGame]>
    func searchSlot(sortBy: GameSorting,
                    isJackpot: Bool,
                    isNew: Bool,
                    featureTags: Set<SlotGameFilter.SlotGameFeature>,
                    themeTags: Set<SlotGameFilter.SlotGameTheme>,
                    payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<[SlotGame]>
    func gameCount(isJackpot: Bool,
                   isNew: Bool,
                   featureTags: Set<SlotGameFilter.SlotGameFeature>,
                   themeTags: Set<SlotGameFilter.SlotGameTheme>,
                   payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<Int>
}

class SlotUseCaseImpl: WebGameUseCaseImpl, SlotUseCase {
    var slotRepository: SlotRepository!
    var localRepository: LocalStorageRepositoryImpl!
    
    var randomPopularSlotGames = BehaviorRelay<[SlotGame]>(value: [])
    lazy var recentSlotGames = slotRepository.getRecentlyPlaySlots().share(replay: 1)
    lazy var newAndJackpotGames = slotRepository.getNewAndJackpotGames().asObservable().share(replay: 1)
    lazy var newSlotGames = newAndJackpotGames.map{ $0.newGame }
    lazy var jackpotSlotGame = newAndJackpotGames.map{ $0.jackpotGames.sorted(by: { $0.jackpotPrize > $1.jackpotPrize }) }
    let REQUEST_GAME_AMOUNT = 10
    let SELECT_GAME_AMOUNT = 2
    let MINIMUM_POPULAR_GAME = 3

    init(_ slotRepository: SlotRepository, _ localRepository: LocalStorageRepositoryImpl) {
        super.init(slotRepository)
        self.slotRepository = slotRepository
        self.localRepository = localRepository
    }
    
    func getPopularSlots() -> Observable<[SlotGame]> {
        return Observable.combineLatest(recentSlotGames, slotRepository.getPopularGames()).scan([SlotGame](), accumulator: { (list, arg1) -> [SlotGame] in
            let (recently, slotHotGames) = arg1
            if list.isEmpty {
                return self.shuffleAndFilterGames(slotHotGames: slotHotGames, recentPlay: recently)
            } else {
                return self.updateHotGames(oldGames: list, newGames: slotHotGames.mostTransactionRanking + slotHotGames.mostWinningAmountRanking)
            }
        }).do(onNext: {[weak self] (slotGames) in
            self?.randomPopularSlotGames.accept(slotGames)
        })
    }
    
    func getRecentlyPlaySlots() -> Observable<[SlotGame]> {
        return recentSlotGames
    }
    
    func getNewSlots() -> Observable<[SlotGame]> {
        return Observable.combineLatest(randomPopularSlotGames, recentSlotGames, newSlotGames) {[weak self] (t1, t2, t3) -> [SlotGame] in
            guard let self = self else { return [] }
            return self.filterExistedGames(source: t3, existing: t1 + t2)
        }
    }
    
    func getJackpotSlots() -> Observable<[SlotGame]> {
        Observable.combineLatest(randomPopularSlotGames, recentSlotGames, newSlotGames, jackpotSlotGame) {[weak self] (t1, t2, t3, t4) -> [SlotGame] in
            guard let self = self else { return [] }
            return self.filterExistedGames(source: t4, existing: t1 + t2 + t3)
        }
    }
    
    func searchSlot(sortBy: GameSorting,
                    isJackpot: Bool,
                    isNew: Bool,
                    featureTags: Set<SlotGameFilter.SlotGameFeature>,
                    themeTags: Set<SlotGameFilter.SlotGameTheme>,
                    payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<[SlotGame]> {
        return slotRepository.searchSlot(sortBy: sortBy, isJackpot: isJackpot, isNew: isNew, featureTags: featureTags, themeTags: themeTags, payLineWayTags: payLineWayTags)
    }
    
    func gameCount(isJackpot: Bool,
                   isNew: Bool,
                   featureTags: Set<SlotGameFilter.SlotGameFeature>,
                   themeTags: Set<SlotGameFilter.SlotGameTheme>,
                   payLineWayTags: Set<SlotGameFilter.SlotPayLineWay>) -> Observable<Int> {
        return slotRepository.gameCount(isJackpot: isJackpot, isNew: isNew, featureTags: featureTags, themeTags: themeTags, payLineWayTags: payLineWayTags)
    }
    
    private func shuffleAndFilterGames(slotHotGames: SlotHotGames, recentPlay: [SlotGame]) -> [SlotGame] {
        let randomMostWinningGames = filterExistedGames(source: slotHotGames.mostWinningAmountRanking, existing: recentPlay).prefix(REQUEST_GAME_AMOUNT).shuffled().prefix(SELECT_GAME_AMOUNT)
        let randomMostTransactionGames = filterExistedGames(source: slotHotGames.mostTransactionRanking, existing: recentPlay).prefix(REQUEST_GAME_AMOUNT)
        return Array(filterExistedGames(source: Array(randomMostTransactionGames), existing: Array(randomMostWinningGames)).prefix(SELECT_GAME_AMOUNT)) + randomMostWinningGames
    }
    
    private func updateHotGames(oldGames: [SlotGame], newGames: [SlotGame]) -> [SlotGame] {
        var newGamesState: [SlotGame] = []
        oldGames.forEach { (oldGame) in
            if let updateFavoriteGame = newGames.first(where: { $0.gameId == oldGame.gameId }) {
                newGamesState.append(updateFavoriteGame)
            }
        }
        
        return newGamesState
    }
    
    private func filterExistedGames(source: [SlotGame], existing: [SlotGame]) -> [SlotGame] {
        return source.filter{ !existing.contains($0) }
    }
}
