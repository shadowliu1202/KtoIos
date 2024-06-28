import RxSwift

protocol WebGameApi{
    func addFavoriteGame(id: Int32) -> Completable
    func removeFavoriteGame(id: Int32) -> Completable
    func getSuggestKeywords() -> Single<[String]?>
    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<String?>
}
