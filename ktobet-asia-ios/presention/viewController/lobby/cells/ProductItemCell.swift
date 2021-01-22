//
//  ProductItemCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit

class ProductItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(_ title : String, img: String){
        labTitle.text = title
        imgIcon.image = UIImage(named: img)
    }
}
