import UIKit

class ChatImageTableViewCell: UITableViewCell {
    static let playerDialogIdentifier = "PlayerImageTableViewCell"
    static let handlerDialogIdentifier = "HandlerImageTableViewCell"
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var img: UIImageView!
}
