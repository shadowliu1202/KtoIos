import Foundation
import RxSwift
import RxCocoa
import SharedBu

typealias WebGameRepository = WebGameFavoriteRepository & WebGameSearchRepository & WebGameCreateRepository

protocol WebGameWithDuplicatable: WebGameWithProperties {
    func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable
}

protocol WebGameFavoriteRepository {
    func addFavorite(game: WebGameWithDuplicatable) -> Completable
    func removeFavorite(game: WebGameWithDuplicatable) -> Completable
    func getFavorites() -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameSearchRepository {
    func getSuggestKeywords() -> Single<[String]>
    func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameCreateRepository {
    func createGame(gameId: Int32) -> Single<URL?>
}

class WebGameRepositoryImpl: WebGameRepository {
    private var api: WebGameApi!
    let favoriteRecord = BehaviorRelay<[WebGameWithDuplicatable]>(value: [])
    
    init(_ api: WebGameApi) {
        self.api = api
    }
    
    func addFavorite(game: WebGameWithDuplicatable) -> Completable {
        return api.addFavoriteGame(id: game.gameId).do(onCompleted: { [weak self] in
             guard let `self` = self else { return }
             var copyValue = self.favoriteRecord.value
             if let i = copyValue.firstIndex(where: { $0.gameId == game.gameId}) {
                copyValue[i] = game.duplicate(isFavorite: true)
             } else {
                let game = game.duplicate(isFavorite: true)
                 copyValue.append(game)
             }
             self.favoriteRecord.accept(copyValue)
         })
    }
    
    func removeFavorite(game: WebGameWithDuplicatable) -> Completable {
        return api.removeFavoriteGame(id: game.gameId).do(onCompleted: { [weak self] in
            guard let `self` = self else { return }
            var copyValue = self.favoriteRecord.value
            if let i = copyValue.firstIndex(where: { $0.gameId == game.gameId}) {
                copyValue[i] = game.duplicate(isFavorite: false)
            } else {
                let game = game.duplicate(isFavorite: false)
                copyValue.append(game)
            }
            self.favoriteRecord.accept(copyValue)
        })
    }
    
    func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        fatalError("Subclasses must override.")
    }
    
    func getSuggestKeywords() -> Single<[String]> {
        return api.getSuggestKeywords().map { (response) -> [String] in
            if let suggestions = response.data {
                return suggestions
            }
            return []
        }
    }
    
    func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        fatalError("Subclasses must override.")
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        return api.getGameUrl(gameId: gameId, siteUrl: KtoURL.baseUrl.absoluteString).map { (response) -> URL? in
            if let path = response.data, let url = URL(string: path) {
                return url
            }
            return nil
        }.catchException(transferLogic: {
            if $0 is GameUnderMaintenance {
                return KtoGameUnderMaintenance()
            }
            return $0
        })
    }
}
