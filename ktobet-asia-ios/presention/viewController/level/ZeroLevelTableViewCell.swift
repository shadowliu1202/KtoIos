import UIKit

class ZeroLevelTableViewCell: UITableViewCell {

    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    func configure(_ item: Item) -> Self {
        self.selectionStyle = .none
        levelLabel.text = "Lv \(item.level)"
        timeLabel.text = item.time
        
        return self
    }
}
