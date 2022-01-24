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
        viewModel.fullscreen().subscribe(onCompleted: { }).disposed(by: disposeBag)
        setupUI()
        textFieldBinding()
        sendMessageBinding()
        uploadImageBinding()
        messageBinding()
        getChatRoomStatus()
    }
    
    // MARK: UI
    private func setupUI() {
        setKeyboardEvent()
        addIndicator()
        setTextFieldPadding()
        textFieldBottomPaddingConstraint.constant = UIDevice.current.hasNotch ? 22 : 0
    }
    
    private func setKeyboardEvent() {
        IQKeyboardManager.shared.enable = false
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addIndicator() {
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
    }
    
    private func setTextFieldPadding() {
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        inputTextField.leftView = paddingView
        inputTextField.leftViewMode = .always
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            textFieldBottomPaddingConstraint.constant = keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        textFieldBottomPaddingConstraint.constant = UIDevice.current.hasNotch ? 22 : 0
    }
    
    // MARK: Binding
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
        
        var firstLoad = true
        viewModel.chatRoomUnreadMessage
            .flatMapLatest { [unowned self] unreadMessages in
                return self.tableView.rx_reachedBottom.map { unreadMessages }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] unreadMessages in
                if unreadMessages.count != 0 && !firstLoad {
                    guard let self = self else { return }
                    self.viewModel.markAllRead().subscribe(onCompleted: { }).disposed(by: self.disposeBag)
                }
                
                firstLoad = false
            }).disposed(by: disposeBag)
        
        var dividerIndex = 0
        messagesOb
            .map({ (read, unread) -> [ChatMessage] in
                if unread.count == 0 {
                    dividerIndex = read.unique { $0.id }.count - 1
                    return read.unique { $0.id }
                } else {
                    dividerIndex = read.unique { $0.id }.count + 1
                    let unreadDivider = ChatMessage.init()
                    return Array(read.unique { $0.id } + [unreadDivider] + unread)
                }
            })
            .do(onNext: { [weak self] data in self?.dataCount = data.count })
                .bind(to: tableView.rx.items) { [weak self] tableView, row, element in
                    guard let self = self else { return UITableViewCell() }
                    var cell: UITableViewCell!
                    
                    switch element {
                    case let message as ChatMessage.Message:
                        
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
                        
                    default:
                        cell = tableView.dequeueReusableCell(withIdentifier: unreadTableViewCell.identifer) as! unreadTableViewCell
                        break
                    }
                    
                    return cell
                }.disposed(by: disposeBag)
        
        messagesOb.subscribe(onNext: { [weak self] (read, unread) in
            DispatchQueue.main.async {
                if dividerIndex > 0 {
                    self?.tableView.scrollToRow(at: IndexPath(row: dividerIndex - 1, section: 0), at: .top, animated: false)
                }
            }
        }).disposed(by: disposeBag)
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
    
    private func getChatRoomStatus() {
        viewModel.preLoadChatRoomStatus.subscribe(onNext: { [weak self] status in
            if status == PortalChatRoom.ConnectStatus.closed {
                self?.disableInputView()
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
        
    // MARK: Upload Image
    private func uploadImageBinding() {
        let uploadTapGesture = UITapGestureRecognizer()
        uploadImageView.addGestureRecognizer(uploadTapGesture)
        uploadTapGesture.rx.event.bind(onNext: { [weak self] recognizer in
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
        imagePickerView.completion = { [weak self] (images) in
            guard let self = self else { return }
            self.startActivityIndicator(activityIndicator: self.activityIndicator)
            self.navigationController?.popViewController(animated: true)
            self.imageIndex = 0
            images.forEach {
                self.uploadImage(image: $0, count: images.count)
            }
        }
        imagePickerView.showImageSizeLimitAlert = { (view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_execeed_limitation"), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageFormatInvalidAlert = { view in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_file_format_invalid"), img: UIImage(named: "Failed"))
        }
        
        self.navigationController?.pushViewController(imagePickerView, animated: true)
    }
    
    private func uploadImage(image: UIImage, count: Int) {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        viewModel.uploadImage(imageData: imageData)
            .do(onSuccess: { [weak self] img in
                guard let self = self else { return }
                self.viewModel.send(image: img).subscribe(onError: { [weak self] error in
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
                self.handleErrors(error)
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }.disposed(by: disposeBag)
    }
    
    private func goExitSurvey() {
        viewModel.findCurrentRoomId().subscribe(onSuccess: { (skillId, roomId) in
            CustomService.switchToExitSurvey(roomId: roomId, skillId: skillId)
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


class MixTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    
    private var disposeBag = DisposeBag()
    
    var maxChatDialogWidth: CGFloat = 0
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        stackView.removeAllArrangedSubviews()
    }
    
    func setContentText(text: ChatMessage.ContentText) {
        let message = text.content.replacingLastOccurrenceOfString("\n", with: "")
        if message.isEmpty {
            return
        }

        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.text = message
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        if let attributes = text.attributes {
            updateText(label: label, attributes: attributes)
        }
        
        stackView.addArrangedSubview(label)
        label.sizeToFit()
        maxChatDialogWidth = maxChatDialogWidth > label.frame.width + 40 ? maxChatDialogWidth : label.frame.width + 40
        stackViewWidth.constant = maxChatDialogWidth
    }
    
    func setImage(image: ChatMessage.ContentImage, root: UIViewController?) {
        let imageDownloader = SDWebImageDownloader.shared
        for header in HttpClient().headers {
            imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        let img = UIImageView()
        img.widthAnchor.constraint(equalToConstant: 200).isActive = true
        img.heightAnchor.constraint(equalToConstant: 200).isActive = true
        img.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer()
        img.sd_setImage(with: URL(string: image.image.path()))
        img.contentMode = .scaleAspectFit
        img.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { recognizer in
            if let vc = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController {
                vc.url = image.image.link()
                vc.thumbnailImage = img.image
                root?.navigationController?.pushViewController(vc, animated: true)
            }
        }).disposed(by: disposeBag)
        
        stackView.addArrangedSubview(img)
    }
    
    func setHyperLinker(text: String) {
        let linkTextView = UITextView()
        linkTextView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        var urlComponents = URLComponents(string: text)!
        if urlComponents.scheme == nil { urlComponents.scheme = "https" }
        let urlStr = urlComponents.url!.absoluteString

        let attributedString = NSMutableAttributedString(string: urlStr)
        let url = URL(string: urlStr)!
        let urlRange = urlStr.startIndex..<urlStr.endIndex
        let convertedRange = NSRange(urlRange, in: urlStr)
        
        attributedString.setAttributes([.link: url], range: convertedRange)
        linkTextView.isEditable = false
        linkTextView.dataDetectorTypes = .all
        linkTextView.attributedText = attributedString
        linkTextView.font = UIFont(name: "PingFangSC-Regular", size: 14.0)!
        linkTextView.backgroundColor = .clear
        linkTextView.linkTextAttributes = [
            .foregroundColor: UIColor.red,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        stackView.addArrangedSubview(linkTextView)
        linkTextView.sizeToFit()
        stackViewWidth.constant = linkTextView.frame.width + 40
    }
    
    private func updateText(label: UILabel, attributes: SharedBu.Attributes) {
        let bold = attributes.bold?.boolValue ?? false
        let italic = attributes.italic?.boolValue ?? false
        let underline = attributes.underline?.boolValue ?? false
        
        var underlineAttribute: [NSAttributedString.Key: Any] = [:]
        
        if italic {
            label.font = UIFont.italicSystemFont(ofSize: 14)
        }
        
        if bold {
            label.font = label.font.with(.traitBold)
        }
        
        if underline {
            underlineAttribute[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.thick.rawValue
            let underlineAttributedString = NSAttributedString(string: label.text ?? "", attributes: underlineAttribute)
            label.attributedText = underlineAttributedString
        }
    }
}
