import UIKit
import share_bu

class ProductItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(_ data : ProductItem){
        labTitle.text = data.title
        imgIcon.image = UIImage(named: data.image)
    }
}
