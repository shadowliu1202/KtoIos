import UIKit
import RxSwift
import SharedBu
import SDWebImage
import IQKeyboardManagerSwift

class ChatRoomViewController: UIViewController {
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: CustomerServiceViewModel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var sendImageView: UIImageView!
    @IBOutlet weak var uploadImageView: UIImageView!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var textFieldBottomPaddingConstraint: NSLayoutConstraint!
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private let disposeBag = DisposeBag()
    private var imagePickerView: ImagePickerViewController!
    private var imageIndex = 0
    private var imageUploadInex = 0
    private var dataCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.shared.enable = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        textFieldBottomPaddingConstraint.constant = UIDevice.current.hasNotch ? 22 : 0
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        viewModel.fullscreen().subscribe(onCompleted: { }).disposed(by: disposeBag)
        setTextFieldPadding()
        textFieldBinding()
        sendMessageBinding()
        uploadImageBinding()
        messageBinding()
        viewModel.preLoadChatRoomStatus.subscribe(onNext: {[weak self] status in
            if status == PortalChatRoom.ConnectStatus.closed {
                self?.disableInputView()
            }
        }).disposed(by: disposeBag)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            textFieldBottomPaddingConstraint.constant = keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        textFieldBottomPaddingConstraint.constant = UIDevice.current.hasNotch ? 22 : 0
    }
    
    private func setTextFieldPadding() {
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        inputTextField.leftView = paddingView
        inputTextField.leftViewMode = .always
    }
    
    private func textFieldBinding() {
        let inputTextObservable = inputTextField.rx.text.share(replay: 1)
        inputTextObservable.map { !$0.isNullOrEmpty() }.bind(to: sendImageView.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        inputTextObservable.map { $0.isNullOrEmpty() ? UIImage(named: "Send Message(Disable)") : UIImage(named: "Send Message") }.bind(to: sendImageView.rx.image).disposed(by: disposeBag)
    }
    
    private func sendMessageBinding() {
        let sendImageViewTapGesture = UITapGestureRecognizer()
        sendImageView.addGestureRecognizer(sendImageViewTapGesture)
        sendImageViewTapGesture.rx.event.bind(onNext: { [weak self] recognizer in
            guard let self = self, let text = self.inputTextField.text else { return }
            
            self.viewModel.send(message: text).subscribe(onError: { _ in
                print("send message error")
            }).disposed(by: self.disposeBag)
            
            self.inputTextField.text = ""
            self.inputTextField.sendActions(for: .valueChanged)
        }).disposed(by: disposeBag)
    }
    
    private func messageBinding() {
        let messagesOb = Observable.combineLatest(viewModel.chatRoomMessage, viewModel.chatRoomUnreadMessage)
            .observeOn(MainScheduler.asyncInstance)
            .share(replay: 1)
        
        viewModel.chatRoomUnreadMessage
            .flatMapLatest {[unowned self] unreadMessages in
            return self.tableView.rx_reachedBottom.map{ unreadMessages }
        }
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onNext: {[weak self] unreadMessages in
            if unreadMessages.count != 0 {
                guard let self = self else { return }
                self.viewModel.markAllRead().subscribe(onCompleted: {}).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        var dividerIndex = 0
        messagesOb
            .map({(read, unread) -> [ChatMessage] in
                if unread.count == 0 {
                    dividerIndex = read.unique{ $0.id }.count - 1
                    return read.unique{ $0.id }
                } else {
                    dividerIndex = read.unique{ $0.id }.count + 1
                    let unreadDivider = ChatMessage.init()
                    return Array(read.unique{ $0.id } + [unreadDivider] + unread)
                }
            })
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
                    cell = tableView.dequeueReusableCell(withIdentifier: CloseSystemDialogTableViewCell.closeIdentifier) as! CloseSystemDialogTableViewCell
                    (cell as! CloseSystemDialogTableViewCell).messageLabel.text = Localize.string("customerservice_chat_room_end_by_host")
                case is ChatMessage.SystemClosed:
                    cell = tableView.dequeueReusableCell(withIdentifier: CloseSystemDialogTableViewCell.closeIdentifier) as! CloseSystemDialogTableViewCell
                    (cell as! CloseSystemDialogTableViewCell).messageLabel.text = Localize.string("customerservice_chat_room_ended_view_history")
                default:
                    cell = tableView.dequeueReusableCell(withIdentifier: unreadTableViewCell.identifer) as! unreadTableViewCell
                    break
                }
                
                return cell
            }.disposed(by: disposeBag)
        
        messagesOb.subscribe(onNext: {[weak self] (read, unread) in
            DispatchQueue.main.async {
                self?.tableView.scrollToRow(at: IndexPath(row: dividerIndex, section: 0), at: .none, animated: false)
            }
        }).disposed(by: disposeBag)
    }
    
    private func disableInputView() {
        uploadImageView.image = UIImage(named: "Take Photo disable")
        uploadImageView.isUserInteractionEnabled = false
        self.inputTextField.text = ""
        self.inputTextField.sendActions(for: .valueChanged)
        inputTextField.placeholder = Localize.string("customerservice_chat_ended")
        inputTextField.isEnabled = false
        sendImageView.isUserInteractionEnabled = false
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
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
            (cell as! ChatImageTableViewCell).img.sd_setImage(with: URL(string: image.image.thumbnailLink()))
            let tapGesture = UITapGestureRecognizer()
            (cell as! ChatImageTableViewCell).img.addGestureRecognizer(tapGesture)
            tapGesture.rx.event.bind(onNext: {[weak self] recognizer in
                if let vc = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController {
                    vc.url = image.image.link()
                    vc.thumbnailImage = (cell as! ChatImageTableViewCell).img.image
                    self?.navigationController?.pushViewController(vc, animated: true)
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
    
    // MARK: Upload Image
    private func uploadImageBinding() {
        let uploadTapGesture = UITapGestureRecognizer()
        uploadImageView.addGestureRecognizer(uploadTapGesture)
        uploadTapGesture.rx.event.bind(onNext: {[weak self] recognizer in
            guard let self = self else { return }
            self.startActivityIndicator(activityIndicator: self.activityIndicator)
            self.showImagePicker()
        }).disposed(by: disposeBag)
    }
    
    private func showImagePicker() {
        imagePickerView = UIStoryboard(name: "ImagePicker", bundle: nil).instantiateViewController(withIdentifier: "ImagePickerViewController") as? ImagePickerViewController
        imagePickerView.delegate = self
        imagePickerView.imageLimitMBSize = DepositViewModel.imageMBSizeLimit
        imagePickerView.selectedImageLimitCount = 3
        imagePickerView.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
        imagePickerView.completion = {[weak self] (images) in
            guard let self = self else { return }
            self.startActivityIndicator(activityIndicator: self.activityIndicator)
            self.navigationController?.popViewController(animated: true)
            self.imageIndex = 0
            images.forEach {
                self.uploadImage(image: $0, count: images.count)
            }
        }
        imagePickerView.showImageSizeLimitAlert = {(view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_execeed_limitation"), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageFormatInvalidAlert = {view in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_file_format_invalid"), img: UIImage(named: "Failed"))
        }
        
        self.navigationController?.pushViewController(imagePickerView, animated: true)
    }
    
    private func uploadImage(image: UIImage, count: Int) {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        viewModel.uploadImage(imageData: imageData)
            .do(onSuccess: {[weak self] img in
                guard let self = self else { return }
                self.viewModel.send(image: img).subscribe(onError: {[weak self] error in
                    self?.handleErrors(error)
                }).disposed(by: self.disposeBag)
            })
            .subscribe { [weak self] (result) in
                guard let self = self else { return }
                self.viewModel.uploadImageDetail[self.imageUploadInex] = result
                self.imageUploadInex += 1
                self.imageIndex += 1
                if count == self.imageIndex {
                    self.stopActivityIndicator(activityIndicator: self.activityIndicator)
                }
            } onError: { [weak self] (error) in
                guard let self = self else { return }
                self.handleUnknownError(error)
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }.disposed(by: disposeBag)
    }
    
    func goExitSurvey() {
        viewModel.findCurrentRoomId().subscribe(onSuccess: { roomId in
            CustomService.switchToExitSurvey(roomId: roomId)
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        print("\(type(of: self)) deinit")
    }
    
}

extension ChatRoomViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case endChatBarBtnId:
            Alert.show(Localize.string("customerservice_chat_room_close_confirm_title"),
                       Localize.string("customerservice_chat_room_close_confirm_content"),
                       confirm: { }, confirmText: Localize.string("common_continue"),
                       cancel: { self.goExitSurvey() },
                       cancelText: Localize.string("common_finish"))
        case collapseBarBtnId:
            CustomService.collapse()
        default:
            break
        }
    }
}

// MARK: CAMERA EVENT
extension ChatRoomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true) {
            NavigationManagement.sharedInstance.popViewController()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                self.startActivityIndicator(activityIndicator: self.activityIndicator)
                self.imageIndex = 0
                self.uploadImage(image: image, count: 1)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
