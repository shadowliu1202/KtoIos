import RxSwift
import sharedbu
import UIKit

typealias ProductFavoriteHelper = ProductsViewController & ProductVCProtocol & WebGameViewCallback
let reuseFooterTag = 300

class ProductGameDataSourceDelegate: NSObject {
  enum CellType {
    case general
    case search
    case loadMore
  }
  
  enum DifferentGames {
    case all
    case some([IndexPath])
  }

  fileprivate var games: [WebGameWithDuplicatable] = []
  fileprivate weak var vc: ProductFavoriteHelper?
  fileprivate var cellType: CellType = .general

  var searchKeyword: String?
  var lookMoreTap: (() -> Void)?
  var isLookMore = false

  private let disposeBag = DisposeBag()

  init(_ vc: ProductFavoriteHelper, cellType: CellType = .general) {
    self.vc = vc
    self.cellType = cellType

    super.init()
  }
  
  func handleGameUpdates(_ games: [WebGameWithDuplicatable]) -> DifferentGames {
    let oldGames = self.games
    setGames(games)
      
    return computeDifferences(oldGames: oldGames, newGames: games)
  }

  func setGames(_ games: [WebGameWithDuplicatable]) {
    self.games = games
  }
  
  private func computeDifferences(oldGames: [WebGameWithDuplicatable], newGames: [WebGameWithDuplicatable]) -> DifferentGames {
    if oldGames.count != newGames.count {
      return .all
    }
    else {
      let differentIndexPaths = newGames.enumerated()
        .filter { !$1.equalTo(other: oldGames[$0]) }
        .map { IndexPath(item: $0.0, section: 0) }
        
      return .some(differentIndexPaths)
    }
  }

  func game(at indexPath: IndexPath) -> WebGameWithDuplicatable {
    self.games[indexPath.row]
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

  @objc
  func lookMore() {
    lookMoreTap?()
  }
}

extension ProductGameDataSourceDelegate: UICollectionViewDataSource {
  func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    self.games.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let game = self.game(at: indexPath)
    var cell: WebGameItemCell
    switch cellType {
    case .general,
         .loadMore:
      cell = collectionView.dequeueReusableCell(cellType: WebGameItemCell.self, indexPath: indexPath).configure(game: game)
    case .search:
      cell = collectionView.dequeueReusableCell(cellType: WebGameSearchItemCell.self, indexPath: indexPath)
        .configure(game: game, searchKeyword: self.searchKeyword)
    }
    cell.favoriteBtnClick = { [weak self] in
      cell.setToggleFavoriteProcessing(true)
      cell.toggleFavoriteIcon()
      
      self?.vc?.toggleFavorite(
        game,
        onCompleted: { action in
          cell.setToggleFavoriteProcessing(false)
          self?.showToast(action)
        },
        onError: { error in
          cell.toggleFavoriteIcon()
          cell.setToggleFavoriteProcessing(false)
          self?.vc?.handleErrors(error)
        })
    }
    
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath)
    -> UICollectionReusableView
  {
    guard cellType == .loadMore else { return UICollectionReusableView() }
    if isLookMore {
      switch kind {
      case UICollectionView.elementKindSectionFooter:
        let reuseView = collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: "Footer",
          for: indexPath)
        if reuseView.tag == 0 {
          let imageView = UIImageView(image: UIImage(named: "see-more"))
          imageView.backgroundColor = UIColor(red: 56 / 255, green: 56 / 255, blue: 56 / 255, alpha: 1.0)
          imageView.sizeToFit()
          imageView.cornerRadius = imageView.frame.width / 2
          imageView.clipsToBounds = true
          reuseView.addSubview(imageView)
          imageView.translatesAutoresizingMaskIntoConstraints = false
          imageView.centerYAnchor.constraint(equalTo: reuseView.centerYAnchor, constant: -18).isActive = true
          imageView.centerXAnchor.constraint(equalTo: reuseView.centerXAnchor, constant: -4).isActive = true
          let textLabel = UILabel()
          reuseView.addSubview(textLabel)
          textLabel.text = Localize.string("product_see_more")
          textLabel.font = UIFont(name: "PingFangSC-Regular", size: 12)
          textLabel.textColor = UIColor.textPrimary
          textLabel.translatesAutoresizingMaskIntoConstraints = false
          textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
          textLabel.centerXAnchor.constraint(equalTo: reuseView.centerXAnchor, constant: -4).isActive = true
          let gesture = UITapGestureRecognizer(target: self, action: #selector(lookMore))
          reuseView.addGestureRecognizer(gesture)
          reuseView.tag = reuseFooterTag
        }
        return reuseView
      default:
        fatalError("Unexpected element kind")
      }
    }
    else {
      let headerView = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: "Footer",
        for: indexPath)
      return headerView
    }
  }
}

extension ProductGameDataSourceDelegate: UICollectionViewDelegate {
  func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard
      let vc = self.vc,
      let viewModel = vc.getProductViewModel()
    else { return }

    let data = self.game(at: indexPath)

    viewModel.fetchGame(data)
  }
}

class SearchGameDataSourceDelegate: ProductGameDataSourceDelegate {
  init(_ vc: ProductFavoriteHelper) {
    super.init(vc, cellType: .search)
  }
}
