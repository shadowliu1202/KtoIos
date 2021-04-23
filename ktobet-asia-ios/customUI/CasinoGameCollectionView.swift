import UIKit
import AlignedCollectionViewFlowLayout

class CasinoGameCollectionView: UICollectionView {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.collectionViewLayout = {
            let space = CGFloat(4)
            let flowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
            flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.minimumLineSpacing = CGFloat(14)
            return flowLayout
        }()
    }
}
