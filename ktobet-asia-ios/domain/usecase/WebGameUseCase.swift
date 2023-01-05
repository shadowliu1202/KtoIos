import Foundation
import SharedBu
import RxSwift

typealias WebGameUseCase = WebGameFavoriteUseCase & WebGameSearchUseCase & WebGameCreateUseCase
protocol WebGameFavoriteUseCase {
    func addFavorite(game: WebGameWithDuplicatable) -> Completable
    func removeFavorite(game: WebGameWithDuplicatable) -> Completable
    func getFavorites() -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameSearchUseCase {
    func getSuggestKeywords() -> Single<[String]>
    func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameCreateUseCase {
    func createGame(gameId: Int32) -> Single<URL?>
}

class WebGameUseCaseImpl: WebGameUseCase {
    var repo : WebGameRepository!
    
    init(_ repo : WebGameRepository) {
        self.repo = repo
    }
    
    func addFavorite(game: WebGameWithDuplicatable) -> Completable {
        repo.addFavorite(game: game)
    }
    
    func removeFavorite(game: WebGameWithDuplicatable) -> Completable {
        repo.removeFavorite(game: game)
    }
    
    func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
        repo.getFavorites()
    }
    
    func getSuggestKeywords() -> Single<[String]> {
        repo.getSuggestKeywords()
    }
    
    func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
        if keyword.isSearchPermitted() {
            return repo.searchGames(keyword: keyword)
        }
        return Observable.just([])
    }
    
    func createGame(gameId: Int32) -> Single<URL?> {
        repo.createGame(gameId: gameId)
    }
}
