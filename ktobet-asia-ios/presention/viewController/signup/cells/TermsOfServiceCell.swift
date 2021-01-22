//
//  TermsOfServiceCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/26.
//

import UIKit

class TermsOfServiceCell: UITableViewCell {

    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var labContent: UILabel!
    @IBOutlet weak var constraintContentTop : NSLayoutConstraint!
    @IBOutlet weak var constraintContentBottom : NSLayoutConstraint!
    @IBOutlet weak var constraintUnderLineHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labTitle.textColor = UIColor.black_two
        labContent.textColor = UIColor.black_two
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(_ data: TermsOfService)  {
        labTitle.text = data.title
        labContent.text = data.selected ? data.content : ""
        constraintContentTop.constant = data.selected ? 12 : 0
        constraintContentBottom.constant = data.selected ? 12 : 0
        constraintUnderLineHeight.constant = data.selected ? 1 : 0
    }

}
