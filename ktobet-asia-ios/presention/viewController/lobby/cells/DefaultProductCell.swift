//
//  GameTypeCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

import UIKit

class DefaultProductCell: UITableViewCell {

    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var viewBg : UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(_ game : DefaultProductItem){
        self.labTitle.text = game.name
        self.labDesc.text = game.desc
        self.viewBg.layer.cornerRadius = 4
        self.viewBg.layer.borderWidth = game.selected ? 2 : 0
        self.viewBg.layer.borderColor = (game.selected ? UIColor.red : UIColor.clear).cgColor
        self.viewBg.layer.masksToBounds = true
    }
}
