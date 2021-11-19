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
                guard let self = self else { return UITableViewCell() }
                var cell: UITableViewCell!
                switch element {
                case let message as ChatMessage.Message:
                    switch message.speaker {
                    case is PortalChatRoom.SpeakerPlayer:
                        cell = self.setDisplayCell(dialogIdentifier: ChatDialogTableViewCell.playerDialogIdentifier,
                                                   imageIdentifier: ChatImageTableViewCell.playerDialogIdentifier,
                                                   linkIndentifer: ChatLinkTableViewCell.playerLinkIdentifier,
                                                   element: element)
                    case is PortalChatRoom.SpeakerHandler:
                        cell = self.setDisplayCell(dialogIdentifier: ChatDialogTableViewCell.handlerDialogIdentifier,
                                                   imageIdentifier: ChatImageTableViewCell.handlerDialogIdentifier,
                                                   linkIndentifer: ChatLinkTableViewCell.handlerLinkIdentifier,
                                                   element: element)
                    case is PortalChatRoom.SpeakerSystem:
                        if self.dataCount - 1 == row && self.dataCount > 1 {
                            cell = tableView.dequeueReusableCell(withIdentifier: "\(CloseSystemDialogTableViewCell.self)") as! CloseSystemDialogTableViewCell
                            let text = message.message as! ChatMessage.ContentText
                            var str = text.content
                            str.insert(contentsOf: "\n", at: str.index(str.firstIndex(where: { $0 == "。" })!, offsetBy: 1))
                            (cell as! CloseSystemDialogTableViewCell).messageLabel.text = str.removeHtmlTag()
                        } else {
                            cell = tableView.dequeueReusableCell(withIdentifier: "\(SystemDialogTableViewCell.self)") as! SystemDialogTableViewCell
                            (cell as! SystemDialogTableViewCell).dateLabel.text = message.createTimeTick.toDateFormatString()
                            let text = message.message as! ChatMessage.ContentText
                            var str = text.content
                            str.insert(contentsOf: "\n", at: str.index(str.firstIndex(where: { $0 == "。" })!, offsetBy: 1))
                            (cell as! SystemDialogTableViewCell).messageLabel.text = str.removeHtmlTag()
                        }
                    default:
                        break
                    }
                case is ChatMessage.Close:
                    cell = tableView.dequeueReusableCell(withIdentifier: SystemDialogTableViewCell.closeIdentifier) as! SystemDialogTableViewCell
                    (cell as! SystemDialogTableViewCell).messageLabel.text = Localize.string("customerservice_chat_room_end_by_host")
                case is ChatMessage.SystemClosed:
                    cell = tableView.dequeueReusableCell(withIdentifier: SystemDialogTableViewCell.closeIdentifier) as! SystemDialogTableViewCell
                    (cell as! SystemDialogTableViewCell).messageLabel.text = Localize.string("customerservice_chat_room_ended_view_history")
                default:
                    cell = tableView.dequeueReusableCell(withIdentifier: unreadTableViewCell.identifer) as! unreadTableViewCell
                    break
                }
                
                return cell
            }.disposed(by: disposeBag)
    }
    
    private func setDisplayCell(dialogIdentifier: String, imageIdentifier: String, linkIndentifer: String, element: ChatMessage) -> UITableViewCell {
        var cell: UITableViewCell!
        let message = element as! SharedBu.ChatMessage.Message
        
        switch message.message {
        case let text as ChatMessage.ContentText:
            cell = tableView.dequeueReusableCell(withIdentifier: dialogIdentifier) as! ChatDialogTableViewCell
            (cell as! ChatDialogTableViewCell).dateLabel.text = message.createTimeTick.toTimeString()
            (cell as! ChatDialogTableViewCell).messageLabel.text = text.content
        case let image as ChatMessage.ContentImage:
            cell = tableView.dequeueReusableCell(withIdentifier: imageIdentifier) as! ChatImageTableViewCell
            let imageDownloader = SDWebImageDownloader.shared
            for header in HttpClient().headers {
                imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            (cell as! ChatImageTableViewCell).dateLabel.text = message.createTimeTick.toTimeString()
            print(image.image.thumbnailLink())
            (cell as! ChatImageTableViewCell).img.sd_setImage(with: URL(string: image.image.thumbnailLink()))
            let tapGesture = UITapGestureRecognizer()
            (cell as! ChatImageTableViewCell).img.addGestureRecognizer(tapGesture)
            tapGesture.rx.event.bind(onNext: { recognizer in
                if let vc = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController {
                    vc.url = image.image.link()
                    vc.thumbnailImage = (cell as! ChatImageTableViewCell).img.image
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: disposeBag)
        case let link as ChatMessage.ContentLink:
            cell = tableView.dequeueReusableCell(withIdentifier: linkIndentifer) as! ChatLinkTableViewCell
            (cell as! ChatLinkTableViewCell).setHyperLinker(text: link.content)
        default:
            break
        }
        
        return cell
    }

}
