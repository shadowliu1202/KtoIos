import UIKit
import share_bu

typealias CasinoFavoriteHelper = CasinoFavoriteProtocol & UIViewController
protocol CasinoFavoriteProtocol: class {
    func toggleFavorite(_ game: CasinoGame, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->())
}

class CasinoGameDataSourceDelegate: NSObject {
    fileprivate var games: [CasinoGame] = []
    fileprivate weak var vc: CasinoFavoriteHelper?
    private var isSearchPage = false
    var searchKeyword: String?
    
    init(_ vc: CasinoFavoriteHelper, isSearchPage: Bool = false) {
        self.vc = vc
        self.isSearchPage = isSearchPage
    }
    
    func setGames(_ games: [CasinoGame]) {
        self.games = games
    }
    
    func game(at indexPath: IndexPath) -> CasinoGame {
        return self.games[indexPath.row]
    }
    
    private func showToast(_ action: FavoriteAction) {
        var text = ""
        var icon = UIImage(named: "")
        switch action {
        case .add:
            text = Localize.string("product_add_favorite")
            icon = UIImage(named: "add-favorite")
        case .remove:
            text = Localize.string("product_remove_favorite")
            icon = UIImage(named: "remove-favorite")
        }
        self.vc?.showToast(ToastPopUp(icon: icon!, text: text))
    }
}

extension CasinoGameDataSourceDelegate: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let game = self.game(at: indexPath)
        var cell: CasinoGameItemCell
        if isSearchPage {
            cell = collectionView.dequeueReusableCell(cellType: CasinoGameSearchItemCell.self, indexPath: indexPath).configure(game: game, searchKeyword: self.searchKeyword)
        } else {
            cell = collectionView.dequeueReusableCell(cellType: CasinoGameItemCell.self, indexPath: indexPath).configure(game: game)
        }
        cell.favoriteBtnClick = {
            self.vc?.toggleFavorite(game, onCompleted: { [weak self] (action) in
                self?.showToast(action)
            }, onError: { [weak self] (error) in
                self?.vc?.handleUnknownError(error)
            })
        }
        return cell
    }
}

extension CasinoGameDataSourceDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = self.game(at: indexPath)
        guard data.gameStatus == .active else { return }
        let storyboard = UIStoryboard(name: "Casino", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GameWebViewViewController") as! GameWebViewViewController
        vc.gameId = data.gameId
        vc.gameProduct = "casino"
        self.vc?.present(vc, animated: true, completion: nil)
    }
}
