import SharedBu
import UIKit

typealias SearchProduct = SearchBaseViewController & SearchBaseCollection

protocol SearchBaseCollection: ProductBaseCollection {
  func setCollectionView() -> UICollectionView
  func setProductGameDataSourceDelegate() -> SearchGameDataSourceDelegate
  func setViewModel() -> ProductViewModel?
}

extension SearchBaseCollection {
  func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
    self.setProductGameDataSourceDelegate()
  }

  func setViewModel() -> DisplayProductViewModel? {
    self.setViewModel()
  }
}

class SearchBaseViewController: DisplayGameCollectionBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setup()
  }

  override func setup() {
    guard let self = self as? SearchProduct else { return }
    let collectionView = self.setCollectionView()
    collectionView.delegate = self.setProductGameDataSourceDelegate()
    collectionView.dataSource = self.setProductGameDataSourceDelegate()
  }
}
