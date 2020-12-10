//
//  FeatureItemCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit

class FeatureItemCell: UITableViewCell {
    
    @IBOutlet private weak var labTitle : UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(_ title : String){
        labTitle.text = title
    }
}
