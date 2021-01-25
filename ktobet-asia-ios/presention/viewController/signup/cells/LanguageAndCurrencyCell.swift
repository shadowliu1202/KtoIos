//
//  RegisterLanguageCell.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

import UIKit

class LanguageAndCurrencyCell: UITableViewCell {

    @IBOutlet weak var background : UIView!
    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var btnSelected: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.masksToBounds = true
        background.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(_ data : SignupLanguageViewController.LanguageListData){
        let tundoraGray = UIColor.inputSelectedTundoraGray
        let shaftGray = UIColor.inputBaseMineShaftGray
        labTitle.text = data.title
        btnSelected.isSelected = data.selected
        background.backgroundColor = data.selected ? tundoraGray : shaftGray
    }
    
}
