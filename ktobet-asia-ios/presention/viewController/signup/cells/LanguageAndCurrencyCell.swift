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
    var didSelectOn: ((UIButton) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        background.layer.masksToBounds = true
        background.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(_ data : SignupLanguageViewController.LanguageListData){
        let tundoraGray = UIColor.gray454545
        let shaftGray = UIColor.gray333333
        labTitle.text = data.title
        labTitle.textColor = data.selected ? UIColor.whitePure : UIColor.gray9B9B9B
        btnSelected.isSelected = data.selected
        background.backgroundColor = data.selected ? tundoraGray : shaftGray
    }
    
    @IBAction func radioBtnPressed(_ sender: UIButton) {
        self.didSelectOn?(sender)
    }
    
}
