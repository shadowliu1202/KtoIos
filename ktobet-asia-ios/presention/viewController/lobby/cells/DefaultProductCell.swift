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
    @IBOutlet private weak var imgBackground : UIImageView!
    @IBOutlet private weak var viewShadow : UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.viewBg.layer.masksToBounds = true
        self.viewBg.layer.cornerRadius = 8
        self.imgBackground?.layer.masksToBounds = true
        self.viewShadow.layer.masksToBounds = false
        self.viewShadow.layer.cornerRadius = 8
        self.viewShadow.layer.shadowColor = UIColor.white.cgColor
        self.viewShadow.layer.shadowPath = UIBezierPath(roundedRect: self.viewBg.bounds,
                                                        cornerRadius: self.viewBg.layer.cornerRadius).cgPath
        self.viewShadow.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.viewShadow.layer.shadowOpacity = 0.7
        self.viewShadow.layer.shadowRadius = 5
    }
    
    func setup(_ game : DefaultProductItem){
        self.imgBackground?.image = game.selected ? game.selectImg : game.unselectImg
        self.labTitle.text = game.name
        self.labDesc.text = game.desc
        self.viewBg.layer.borderWidth = game.selected ? 1 : 0
        self.viewBg.layer.borderColor = (game.selected ? UIColor.white : UIColor.clear).cgColor
        self.viewShadow.isHidden = !game.selected
    }
}
