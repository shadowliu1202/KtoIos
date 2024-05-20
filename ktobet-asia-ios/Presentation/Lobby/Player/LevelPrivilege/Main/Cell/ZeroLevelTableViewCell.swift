import UIKit

class ZeroLevelTableViewCell: UITableViewCell {
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    func configure(_ item: LevelPrivilegeViewModel.Item) -> Self {
        self.selectionStyle = .none
        levelLabel.text = Localize.string("common_level_2", "\(item.level)")
        timeLabel.text = item.time

        return self
    }
}
