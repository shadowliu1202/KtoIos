import UIKit
import SharedBu
import RxSwift

typealias ProductFavoriteHelper = ProductsViewController & ProductVCProtocol & WebGameViewCallback

class ProductGameDataSourceDelegate : NSObject {
    enum CellType {
        case general
        case search
        case loadMore
    }
    fileprivate var games: [WebGameWithDuplicatable] = []
    fileprivate weak var vc: ProductFavoriteHelper?
    fileprivate var cellType: CellType = .general
    var searchKeyword: String?
    var lookMoreTap: (() -> ())?
    var isLookMore: Bool = false
    
    init(_ vc: ProductFavoriteHelper, cellType: CellType = .general) {
        self.vc = vc
        self.cellType = cellType
    }
    
    func setGames(_ games: [WebGameWithDuplicatable]) {
        self.games = games
    }
    
    func game(at indexPath: IndexPath) -> WebGameWithDuplicatable {
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
        self.vc?.showToastOnCenter(ToastPopUp(icon: icon!, text: text))
    }
    
    @objc func lookMore() {
        lookMoreTap?()
    }
}

extension ProductGameDataSourceDelegate: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let game = self.game(at: indexPath)
        var cell: WebGameItemCell
        switch cellType {
        case .general, .loadMore:
            cell = collectionView.dequeueReusableCell(cellType: WebGameItemCell.self, indexPath: indexPath).configure(game: game)
        case .search:
            cell = collectionView.dequeueReusableCell(cellType: WebGameSearchItemCell.self, indexPath: indexPath).configure(game: game, searchKeyword: self.searchKeyword)
        }
        cell.favoriteBtnClick = { (favoriteBtn) in
            favoriteBtn?.isUserInteractionEnabled = false
            self.vc?.toggleFavorite(game, onCompleted: { [weak self] (action) in
                favoriteBtn?.isUserInteractionEnabled = true
                self?.showToast(action)
            }, onError: { [weak self] (error) in
                favoriteBtn?.isUserInteractionEnabled = true
                self?.vc?.handleErrors(error)
            })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard cellType == .loadMore else { return UICollectionReusableView() }
        if isLookMore {
            switch kind {
            case UICollectionView.elementKindSectionFooter:
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
                let imageView = UIImageView(image: UIImage(named: "see-more"))
                imageView.backgroundColor = UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1.0)
                imageView.sizeToFit()
                imageView.cornerRadius = imageView.frame.width / 2
                imageView.clipsToBounds = true
                headerView.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: -18).isActive = true
                imageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: -4).isActive = true
                let textLabel = UILabel()
                headerView.addSubview(textLabel)
                textLabel.text = Localize.string("product_see_more")
                textLabel.font = UIFont(name: "PingFangSC-Regular", size: 12)
                textLabel.textColor = UIColor.textPrimaryDustyGray
                textLabel.translatesAutoresizingMaskIntoConstraints = false
                textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
                textLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: -4).isActive = true
                let gesture = UITapGestureRecognizer(target: self, action: #selector(lookMore))
                headerView.addGestureRecognizer(gesture)
                return headerView
            default:
                fatalError("Unexpected element kind")
            }
        } else {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
            return headerView
        }
    }
}

extension ProductGameDataSourceDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let vc = self.vc, let viewModel = vc.getProductViewModel() else { return }
        let data = self.game(at: indexPath)
        switch data.gameState() {
        case .active:
            vc.goToWebGame(viewModel: viewModel, gameId: data.gameId, gameName: data.gameName)
        default:
            break
        }
    }
    
}

class SearchGameDataSourceDelegate: ProductGameDataSourceDelegate {
    init(_ vc: ProductFavoriteHelper) {
        super.init(vc, cellType: .search)
    }
}
