import UIKit
import RxSwift
import SharedBu
import SDWebImage

class ChatHistoryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var roomId: String!
    
    private var viewModel = DI.resolve(CustomerServiceHistoryViewModel.self)!
    private var dataCount = 0
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, leftItemTitle: Localize.string("customerservice_history_title"))
        
        viewModel.getChatHistory(roomId: roomId)
            .do(onNext: {[weak self] data in self?.dataCount = data.count })
            .bind(to: tableView.rx.items) {[weak self] tableView, row, element in
                guard let self = self, let message = element as? ChatMessage.Message else { return UITableViewCell() }
                var cell: UITableViewCell!
                
                switch message.speaker {
                case is PortalChatRoom.SpeakerPlayer:
                    cell = self.setHandlerCell(message: message, identifier: "MixPlayerTableViewCell")
                case is PortalChatRoom.SpeakerHandler:
                    cell = self.setHandlerCell(message: message, identifier: "MixHandlerTableViewCell")
                case is PortalChatRoom.SpeakerSystem:
                    if self.dataCount - 1 == row && self.dataCount > 1 {
                        cell = tableView.dequeueReusableCell(withIdentifier: "\(CloseSystemDialogTableViewCell.self)") as! CloseSystemDialogTableViewCell
                        let message = message.message.map { ($0 as! ChatMessage.ContentText).content }.joined(separator: "")
                        var str = message
                        str.insert(contentsOf: "\n", at: str.index(str.firstIndex(where: { $0 == "。" })!, offsetBy: 1))
                        (cell as! CloseSystemDialogTableViewCell).messageLabel.text = str
                    } else {
                        cell = tableView.dequeueReusableCell(withIdentifier: "\(SystemDialogTableViewCell.self)") as! SystemDialogTableViewCell
                        (cell as! SystemDialogTableViewCell).dateLabel.text = message.createTimeTick.toDateFormatString()
                        let message = message.message.map { ($0 as! ChatMessage.ContentText).content }.joined(separator: "")
                        var str = message
                        str = str.replacingLastOccurrenceOfString("\n", with: "")
                        (cell as! SystemDialogTableViewCell).messageLabel.text = str
                    }
                default:
                    break
                }
                
                return cell
            }.disposed(by: disposeBag)
    }
    
    private func setHandlerCell(message: ChatMessage.Message, identifier: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! MixTableViewCell
        cell.stackView.layoutMargins = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        cell.stackView.isLayoutMarginsRelativeArrangement = true
        cell.dateLabel.text = message.createTimeTick.toTimeString()
        let messages = message.message.filter { it in
            if let text = it as? ChatMessage.ContentText {
                return text.content != "\n"
            }

            return true
        }
        
        cell.maxChatDialogWidth = 0

        for m in messages {
            switch m {
            case let text as ChatMessage.ContentText:
                cell.setContentText(text: text)
            case let image as ChatMessage.ContentImage:
                cell.setImage(image: image, root: self)
            case let link as ChatMessage.ContentLink:
                cell.setHyperLinker(text: link.content)
            default:
                break
            }
        }
        
        return cell
    }

}
