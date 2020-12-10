//
//  ProductItemCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit

class ProductItemCell: UICollectionViewCell {
    
    @IBOutlet private weak var labTitle : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .red
    }
    
    func setup(_ title : String){
        labTitle.text = title
    }
}
