import RxSwift

typealias WebGameApi = WebGameCreateApi & WebGameFavoriteApi & WebGameSearchApi
protocol WebGameFavoriteApi {
    func addFavoriteGame(id: Int32) -> Completable
    func removeFavoriteGame(id: Int32) -> Completable
    func getFavoriteGameList<T: Codable>() -> Single<ResponseData<[T]>>
}

protocol WebGameSearchApi {
    func getSuggestKeywords() -> Single<ResponseData<[String]>>
    func searchGameList<T: Codable>(keyword: String) -> Single<ResponseData<[T]>>
}

protocol WebGameCreateApi {
    func getGameUrl(gameId: Int32, siteUrl: String) -> Single<ResponseData<String>>
}
