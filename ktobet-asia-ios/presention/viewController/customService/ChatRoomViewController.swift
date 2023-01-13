import UIKit
import RxSwift
import SharedBu
import SDWebImage
import IQKeyboardManagerSwift
import SwiftUI

class ChatRoomViewController: CommonViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var sendImageView: UIImageView!
    @IBOutlet weak var uploadImageView: UIImageView!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var textFieldBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerContainer: UIView!
    
    private let inputTextFieldTextCountLimit = 500
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var disposeBag = DisposeBag()
    private var imagePickerView: ImagePickerViewController!
    private var imageIndex = 0
    private var imageUploadInex = 0
    private var dataCount = 0
    
    var banner: UIView?
    
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: CustomerServiceViewModel!
    var surveyViewModel: SurveyViewModel!
    
    // FIXME: Use viewDidLoad after resolve memory leak
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fullscreen().subscribe().disposed(by: disposeBag)
        setupUI()
        textFieldBinding()
        sendMessageBinding()
        uploadImageBinding()
        messageBinding()
        getChatRoomStatus()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        IQKeyboardManager.shared.enable = true
        disposeBag = DisposeBag()
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
        
        inputTextField.rx.text
            .orEmpty
            .subscribe(onNext: { [weak self] text in
                self?.textChanged(text)
            })
            .disposed(by: disposeBag)
    }
    
    private func sendMessageBinding() {
        let sendImageViewTapGesture = UITapGestureRecognizer()
        sendImageView.addGestureRecognizer(sendImageViewTapGesture)
        sendImageViewTapGesture.rx.event.bind(onNext: { [weak self] recognizer in
            guard let self = self, let text = self.inputTextField.text else { return }
            
            self.viewModel.send(message: text).subscribe(onError: {[weak self] error in
                self?.handleErrors(error)
            }).disposed(by: self.disposeBag)
            
            self.inputTextField.text = ""
            self.inputTextField.sendActions(for: .valueChanged)
        }).disposed(by: disposeBag)
    }
    
    private func messageBinding() {
        let messagesOb = Observable.combineLatest(viewModel.chatRoomMessage, viewModel.chatRoomUnreadMessage)
            .observe(on: MainScheduler.asyncInstance)
            .share(replay: 1)
        
        var firstLoad = true
        viewModel.chatRoomUnreadMessage
            .flatMapLatest { [unowned self] unreadMessages in
                return self.tableView.rx.reachedBottom.map { unreadMessages }
            }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] unreadMessages in
                if unreadMessages.count != 0 && !firstLoad {
                    guard let self = self else { return }
                    self.viewModel.markAllRead().subscribe(onCompleted: { }).disposed(by: self.disposeBag)
                }
                
                firstLoad = false
            })
            .disposed(by: disposeBag)
        
        var dividerIndex = 0
        messagesOb
            .map { (read, unread) -> NSArray in
                if unread.count == 0 {
                    dividerIndex = read.unique { $0.id }.count - 1
                    return read.unique { $0.id } as NSArray
                } else {
                    dividerIndex = read.unique { $0.id }.count + 1
                    let unreadDivider = UnreadDivider()
                    return Array(read.unique { $0.id } + [unreadDivider] + unread) as NSArray
                }
            }
            .do(onNext: { [weak self] data in self?.dataCount = data.count })
            .bind(to: tableView.rx.items) { [weak self] tableView, row, element in
                guard let self = self else { return UITableViewCell.empty }
                var cell = UITableViewCell.empty
                
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
                            (cell as! CloseSystemDialogTableViewCell).messageLabel.text = message
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
                    
                case is UnreadDivider:
                    cell = tableView.dequeueReusableCell(withIdentifier: unreadTableViewCell.identifer) as! unreadTableViewCell
                default:
                    break
                }
                
                return cell
            }
            .disposed(by: disposeBag)
        
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
        
        viewModel.chatMaintenanceStatus.subscribe {[weak self] isMaintain in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if isMaintain.boolValue {
                    self.viewModel.closeChatRoom().subscribe().disposed(by: self.disposeBag)
                    self.handleMaintenance()
                }
            }
        } onError: {[weak self] error in
            self?.handleErrors(error)
        }.disposed(by: self.disposeBag)
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
            self.showImagePicker()
        }).disposed(by: disposeBag)
    }
    
    private func showImagePicker() {
        imagePickerView = UIStoryboard(name: "ImagePicker", bundle: nil).instantiateViewController(withIdentifier: "ImagePickerViewController") as? ImagePickerViewController
        imagePickerView.delegate = self
        imagePickerView.imageLimitMBSize = DepositLogViewModel.imageMBSizeLimit
        imagePickerView.selectedImageLimitCount = 3
        imagePickerView.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
        imagePickerView.completion = { [weak self] (images) in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
            self.imageIndex = 0
            self.startActivityIndicator(activityIndicator: self.activityIndicator)
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
            } onFailure: { [weak self] (error) in
                guard let self = self else { return }
                self.handleErrors(error)
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }.disposed(by: disposeBag)
    }
    
    private func confirmNetworkThenCloseChatRoom() {
        if NetworkStateMonitor.shared.isNetworkConnected == true {
            viewModel.findCurrentRoomId()
                .flatMap { [unowned self] (skillId, roomId) in
                    self.viewModel.closeChatRoom().andThen(prepareExitSurvey(skillId, roomId))
                }
                .subscribe(onSuccess: goToExitSurvey, onFailure: handleErrors)
                .disposed(by: self.disposeBag)
        } else {
            showToastOnBottom(Localize.string("common_unknownhostexception"), img: UIImage(named: "Failed"))
        }
    }

    private func prepareExitSurvey(_ skillId: SkillId, _ roomId: RoomId) -> Single<(SkillId, RoomId, Survey)>{
        surveyViewModel.getExitSurvey(skillId: skillId).map { survey in (skillId, roomId, survey) }
    }

    private func goToExitSurvey(skillId: SkillId, roomId: RoomId, exitSurvey: Survey) {
        if exitSurvey.surveyQuestions.isEmpty {
            CustomServicePresenter.shared.closeService()
                .subscribe()
                .disposed(by: disposeBag)
        } else {
            CustomServicePresenter.shared.switchToExitSurvey(roomId: roomId, skillId: skillId)
        }
    }
    
    override func networkDidConnectedHandler() {
        removeBanner()
    }
    
    override func networkDisconnectHandler() {
        addBanner()
    }
    
    private func addBanner() {
        guard banner == nil else { return }
        banner = UIHostingController(rootView: BannerView()).view
        banner?.backgroundColor = .clear
        UIView.animate(withDuration: 0.0,
                       delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1,
                       options: [.curveLinear, .allowUserInteraction],
                       animations: { [unowned self] in
                          self.bannerContainer.addSubview(self.banner!, constraints: .fill())
                       },
                       completion: nil)
    }
    
    private func removeBanner() {
        banner?.removeFromSuperview()
        banner = nil
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
            Alert.shared.show(Localize.string("customerservice_chat_room_close_confirm_title"),
                       Localize.string("customerservice_chat_room_close_confirm_content"),
                       confirm: { }, confirmText: Localize.string("common_continue"),
                       cancel: { self.confirmNetworkThenCloseChatRoom() },
                       cancelText: Localize.string("common_finish"))
        case collapseBarBtnId:
            self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
            CustomServicePresenter.shared.collapse()
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

extension ChatRoomViewController {
    
    func textChanged(_ text: String) {
        if let markedRange = inputTextField.markedTextRange,
           inputTextField.position(from: markedRange.start, offset: 0) != nil {
            return
        }
        
        var updatedText = inputTextField.text ?? ""
        
        if text.count > inputTextFieldTextCountLimit {
            updatedText = String(text[..<text.index(text.startIndex, offsetBy: inputTextFieldTextCountLimit)])
        }
        
        inputTextField.remainCursor(to: updatedText)
    }
}

class MixTableViewCell: UITableViewCell {
    private var httpClient = Injectable.resolve(HttpClient.self)!
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        
        
        let text = label.text ?? ""
        let parseText = getLinkTextRange(str: text)
        let underlineAttriString = NSMutableAttributedString(string: text)
        
        parseText.forEach { (url, range) in
            underlineAttriString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            underlineAttriString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.redF20000, range: range)
        }
        
        label.attributedText = underlineAttriString
        
        stackView.addArrangedSubview(label)
        label.sizeToFit()
        maxChatDialogWidth = maxChatDialogWidth > label.frame.width + 40 ? maxChatDialogWidth : label.frame.width + 40
        stackViewWidth.constant = maxChatDialogWidth
    }
    
    func setImage(image: ChatMessage.ContentImage, root: UIViewController?) {
        let imageDownloader = SDWebImageDownloader.shared
        for header in httpClient.headers {
            imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        let img = UIImageView()
        img.widthAnchor.constraint(equalToConstant: 200).isActive = true
        img.heightAnchor.constraint(equalToConstant: 200).isActive = true
        img.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer()
        img.sd_setImage(url: URL(string: image.image.thumbnailLink()), placeholderImage: nil)
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
        linkTextView.isEditable = false
        linkTextView.font = UIFont(name: "PingFangSC-Regular", size: 14.0)!
        linkTextView.backgroundColor = .clear
            
        if let url = URL(string: text) {
            let urlStr = url.absoluteString
            
            let attributedString = NSMutableAttributedString(string: urlStr)
            let urlRange = urlStr.startIndex..<urlStr.endIndex
            let convertedRange = NSRange(urlRange, in: urlStr)
            
            attributedString.setAttributes([.link: url], range: convertedRange)
            linkTextView.attributedText = attributedString
            linkTextView.dataDetectorTypes = .all
            linkTextView.linkTextAttributes = [
                .foregroundColor: UIColor.redF20000,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        }
        else {
            linkTextView.text = text
        }
        
        stackView.addArrangedSubview(linkTextView)
        linkTextView.sizeToFit()
        stackViewWidth.constant = linkTextView.frame.width + 40
    }
    
    private func getLinkTextRange(str: String) -> [(URL?, NSRange)] {
        let types: NSTextCheckingResult.CheckingType = [.link]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let links = detector.matches(in: str, range: NSRange(str.startIndex..., in: str))
            return links.map{ ($0.url ,$0.range) }
        }
        
        return []
    }
    
    private func updateText(label: UILabel, attributes: SharedBu.Attributes) {
        let bold = attributes.bold?.boolValue ?? false
        let italic = attributes.italic?.boolValue ?? false
        let underline = attributes.underline?.boolValue ?? false
        
        
        if italic {
            label.font = UIFont.italicSystemFont(ofSize: 14)
        }
        
        if bold {
            label.font = label.font.with(.traitBold)
        }
        
        if underline {
            var underlineAttribute: [NSAttributedString.Key: Any] = [:]
            underlineAttribute[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.thick.rawValue
            let underlineAttributedString = NSAttributedString(string: label.text ?? "", attributes: underlineAttribute)
            label.attributedText = underlineAttributedString
        }
    }
    
    @objc func tapFunction(sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel,
              let text = label.text else { return }
        
        let parseText = getLinkTextRange(str: text)
        parseText.forEach { (url, range) in
            if sender.didTapAttributedTextInLabel(label: label, inRange: range) {
                UIApplication.shared.open(url!)
            }
        }
    }
}

class UnreadDivider { }

private extension UITableViewCell {
    
    static let empty: UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        let view = UIView()
        cell.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(1)
        }
        
        return cell
    }()
}
