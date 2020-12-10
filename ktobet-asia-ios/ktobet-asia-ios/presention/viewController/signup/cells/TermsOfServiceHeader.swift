//
//  TermsOfServiceHeader.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/26.
//

import UIKit

class TermsOfServiceHeader: UITableViewCell {
    
    @IBOutlet weak var labContent: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(_ data : TermsOfService){
        labContent.text = data.content
    }
}
