import UIKit

extension UICollectionView {
    /// Get customized "UICollectionCell" from "UICollectionView"
    /// - Parameters:
    ///     - identifier: The *identifier* is reuse identifier
    ///     - cellType: The *cellType* is table cell class type
    func dequeueReusableCell<T>(
        withIdentifier identifier: String = String(describing: T.self),
        cellType _: T.Type,
        indexPath: IndexPath)
        -> T
    {
        self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }

    func registerCellFromNib(_ id: String?) {
        guard let id else { return }
        register(UINib(nibName: id, bundle: nil), forCellWithReuseIdentifier: id)
    }
}

extension UICollectionViewCell {
    static var className: String {
        String(describing: self.self)
    }
}
