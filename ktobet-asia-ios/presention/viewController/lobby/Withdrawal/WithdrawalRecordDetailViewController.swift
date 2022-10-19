import UIKit
import RxSwift
import SharedBu
import Photos

class WithdrawalRecordDetailViewController: LobbyViewController {
    @IBOutlet private weak var titleNameLabel: UILabel!
    @IBOutlet private weak var amountTitleLabel: UILabel!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var applytimeTitleLabel: UILabel!
    @IBOutlet private weak var withdrawalIdTitleLabel: UILabel!
    @IBOutlet private weak var uploadTitleLabel: UILabel!
    @IBOutlet private weak var remarkTitleLabel: UILabel!
    
    @IBOutlet private weak var remarkTableview: UITableView!
    
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var statusView: UIView!
    @IBOutlet private weak var statusDateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var applytimeLabel: UILabel!
    @IBOutlet private weak var withdrawalIdLabel: UILabel!
    
    @IBOutlet private weak var uploadView: UIView!
    @IBOutlet private weak var amountView: UIView!
    @IBOutlet private weak var applyTimeView: UIView!
    @IBOutlet private weak var remarkView: UIView!
    @IBOutlet private weak var uploadClickView: UIView!
    @IBOutlet private weak var clickUploadLabel: UILabel!
    @IBOutlet private weak var uploadLimitTiplabel: UILabel!
    
    @IBOutlet private weak var uploadViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var statusViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var remarkViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var remarkTableViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var imageStackViewHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var imageStackView: UIStackView!
    @IBOutlet private weak var scrollview: UIScrollView!
    @IBOutlet private weak var buttonStackView: UIStackView!
    
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    var displayId: String!
    var transactionTransactionType: TransactionType!
    
    private var viewModel = DI.resolve(WithdrawalViewModel.self)!
    private let httpClient = DI.resolve(HttpClient.self)!
    private var uploadViewModel = DI.resolve(UploadPhotoViewModel.self)!
    private var disposeBag = DisposeBag()
    private var removeButtons: [UIButton] = []
    private var isOverImageLimit = false
    private var imageIndex = 0
    private var imageUploadInex = 0
    private var imagePickerView: ImagePickerViewController!
    private var statusChangeHistories: [Transaction.StatusChangeHistory] = []
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
        eventHandler()
        openPhoto()
    }
    
    // MARK: METHOD
    private func initUI() {
        remarkTableview.dataSource = self
        DispatchQueue.main.async {
            self.scrollview.isHidden = true
            self.titleNameLabel.text = Localize.string("withdrawal_detail_title")
            self.amountTitleLabel.text = Localize.string("common_transactionamount")
            self.statusTitleLabel.text = Localize.string("common_status")
            self.applytimeTitleLabel.text = Localize.string("common_applytime")
            self.withdrawalIdTitleLabel.text = Localize.string("withdrawal_id")
            self.remarkTitleLabel.text = Localize.string("common_remark")
            self.uploadTitleLabel.text = Localize.string("common_upload_file")
            self.clickUploadLabel.text = Localize.string("common_click_to_upload")
            self.uploadLimitTiplabel.text = Localize.string("common_photo_upload_limit")
            self.confirmButton.setTitle(Localize.string("common_submit"), for: .normal)
            self.confirmButton.isEnabled = false
            self.confirmButton.layer.borderWidth = 1
            self.confirmButton.layer.borderColor = UIColor.textSecondaryScorpionGray.cgColor
            self.cancelButton.setTitle(Localize.string("withdrawal_cancel"), for: .normal)
            self.amountView.addBorder(.top)
            self.amountView.addBorder(.bottom, rightConstant: 30, leftConstant: 30)
            self.applyTimeView.addBorder(.top, rightConstant: 30, leftConstant: 30)
            self.applyTimeView.addBorder(.bottom, rightConstant: 30, leftConstant: 30)
            self.remarkView.addBorder(.top, rightConstant: 30, leftConstant: 30)
            self.activityIndicator.center = self.view.center
            self.view.addSubview(self.activityIndicator)
        }
    }
    
    private func dataBinding() {
        viewModel.getWithdrawalRecordDetail(transactionId: displayId, transactionTransactionType: transactionTransactionType).subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                if let generalData = data as? WithdrawalDetail.General {
                    self?.updateUI(detail: generalData)
                    self?.statusChangeHistories = generalData.statusChangeHistories
                    self?.remarkTableview.reloadData()
                }
            }, onError: handleErrors).disposed(by: disposeBag)
    }
    
    private func updateUI(detail: WithdrawalDetail.General) {
        DispatchQueue.main.async {
            self.remarkView.removeBorder(.bottom)
            self.scrollview.isHidden = false
            self.applytimeLabel.text = detail.record.createDate.toDateTimeString()
            self.amountLabel.text = detail.record.cashAmount.description()
            self.withdrawalIdLabel.text = detail.record.displayId
            self.statusLabel.text = StringMapper.parse(detail.record.transactionStatus, isPendingHold: detail.isPendingHold, ignorePendingHold: false)
            self.statusDateLabel.text = detail.updatedDate.toDateTimeString()
            self.uploadViewHeight.constant = 0
            self.statusViewHeight.constant = 77
            self.statusDateLabel.isHidden = false
            self.confirmButton.isHidden = true
            self.cancelButton.isHidden = true
            self.uploadView.isHidden = true
            if detail.record.transactionStatus == TransactionStatus.floating {
                self.uploadViewHeight.constant = 171
                self.confirmButton.isHidden = false
                self.cancelButton.isHidden = false
                self.uploadView.isHidden = false
            }
            
            if detail.record.transactionStatus == TransactionStatus.pending {
                if !detail.isPendingHold {
                    self.statusDateLabel.isHidden = true
                    self.statusDateLabel.text = ""
                    self.statusViewHeight.constant = 60
                    self.cancelButton.isHidden = false
                } else {
                    self.statusDateLabel.isHidden = false
                }
                
                self.buttonStackView.removeArrangedSubview(self.confirmButton)
            }
            
            self.cancelButton.isHidden = !detail.isCancellable()
            self.statusView.layoutIfNeeded()
            self.remarkTableview.layoutIfNeeded()
            self.remarkTableViewHeight.constant = self.remarkTableview.contentSize.height
            self.remarkTableview.layoutIfNeeded()
            self.remarkViewHeight.constant = self.remarkTableViewHeight.constant + self.uploadViewHeight.constant + 60
            self.remarkView.layoutIfNeeded()
            if detail.record.transactionStatus != .floating {
                self.remarkView.addBorder(.bottom)
            }
        }
    }
    
    private func eventHandler() {
        self.confirmButton.rx.tap.subscribe(onNext: cofirmUploadImage).disposed(by: self.disposeBag)
        self.cancelButton.rx.tap.subscribe(onNext: cancelWithdrawal).disposed(by: self.disposeBag)
    }
    
    private func cofirmUploadImage() {
        self.viewModel.bindingImageWithWithdrawalRecord(displayId: displayId, transactionId: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus: .pending), portalImages: self.viewModel.uploadImageDetail.map { $0.value.portalImage })
            .do(onSubscribe: { [unowned self] in
                self.startActivityIndicator(activityIndicator: self.activityIndicator)
            }, onDispose: { [unowned self] in
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }).subscribe(onCompleted: viewModel.refreshRecordDetail, onError: handleErrors)
            .disposed(by: self.disposeBag)
    }
    
    private func cancelWithdrawal() {
        self.viewModel.cancelWithdrawal(ticketId: displayId)
            .do(onSubscribe: { [unowned self] in
                self.startActivityIndicator(activityIndicator: self.activityIndicator)
            }, onDispose: { [unowned self] in
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }).subscribe(onCompleted: viewModel.refreshRecordDetail, onError: handleErrors)
            .disposed(by: disposeBag)
    }
    
    private func openPhoto() {
        let tap = UITapGestureRecognizer.init()
        self.uploadClickView.addGestureRecognizer(tap)
        tap.rx.event.subscribe {[weak self] (gesture) in
            self?.showImagePicker()
        }.disposed(by: self.disposeBag)
    }
    
    private func showImagePicker() {
        let currentSelectedImageCount = self.imageStackView.subviews.count
        if currentSelectedImageCount >= WithdrawalViewModel.selectedImageCountLimit {
            Alert.shared.show("", String(format: Localize.string("common_photo_upload_limit_reached"), "\(WithdrawalViewModel.selectedImageCountLimit)"), confirm: nil, cancel: nil)
        }
        
        imagePickerView = UIStoryboard(name: "ImagePicker", bundle: nil).instantiateViewController(withIdentifier: "ImagePickerViewController") as? ImagePickerViewController
        imagePickerView.delegate = self
        imagePickerView.imageLimitMBSize = WithdrawalViewModel.imageMBSizeLimit
        imagePickerView.selectedImageLimitCount = WithdrawalViewModel.selectedImageCountLimit - currentSelectedImageCount
        imagePickerView.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
        imagePickerView.completion = {[weak self] (images) in
            guard let self = self else { return }
            self.startActivityIndicator(activityIndicator: self.activityIndicator)
            NavigationManagement.sharedInstance.popViewController()
            self.imageIndex = 0
            images.forEach {
                self.uploadImage(image: $0, count: images.count)
            }
        }
        imagePickerView.showImageCountLimitAlert = {(view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: String(format: Localize.string("common_photo_upload_limit_count"), String(WithdrawalViewModel.selectedImageCountLimit - currentSelectedImageCount)), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageSizeLimitAlert = {(view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_execeed_limitation"), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageFormatInvalidAlert = {(view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_file_format_invalid"), img: UIImage(named: "Failed"))
        }
        
        NavigationManagement.sharedInstance.pushViewController(vc: imagePickerView)
    }
    
    private func uploadImage(image: UIImage, count: Int) {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        uploadViewModel.uploadImage(imageData: imageData).subscribe {[weak self] (result) in
            guard let self = self else { return }
            self.viewModel.uploadImageDetail[self.imageUploadInex] = result
            self.confirmButton.isEnabled = true
            self.confirmButton.setTitleColor(UIColor.redForDarkFull, for: .normal)
            self.addImageToUI(image: image)
            self.imageUploadInex += 1
            self.imageIndex += 1
            if count == self.imageIndex {
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }
        } onError: { (error) in
            self.handleErrors(error)
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
        }.disposed(by: disposeBag)
    }
    
    private func addImageToUI(image: UIImage) {
        let y = self.imageStackView.frame.origin.y + CGFloat(self.imageStackView.subviews.count * 192)
        let imageView = UIImageView()
        imageView.tag = imageUploadInex
        imageView.image = image
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        self.imageStackViewHeight.constant += 192
        self.uploadViewHeight.constant += 192
        self.remarkViewHeight.constant += 192
        self.imageStackView.addArrangedSubview(imageView)
        let removeButton = UIButton(frame: CGRect(x: self.imageStackView.frame.origin.x + CGFloat(12),
                                                  y: CGFloat(y) + CGFloat(12),
                                                  width: 52, height: 32))
        removeButton.backgroundColor = UIColor.iconBlack2.withAlphaComponent(0.5)
        removeButton.layer.cornerRadius = 10
        removeButton.tag = imageUploadInex
        let attributedString = NSMutableAttributedString(string: Localize.string("common_remove"), attributes: [
            .font: UIFont(name: "PingFangSC-Medium", size: 14.0)!,
            .foregroundColor: UIColor.whiteFull,
            .kern: 0.0
        ])
        
        removeButton.setAttributedTitle(attributedString, for: .normal)
        removeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.removeImage(sender: removeButton)
        }).disposed(by: disposeBag)
        
        
        uploadView.addSubview(removeButton)
        removeButtons.append(removeButton)
    }
    
    private func removeImage(sender: UIButton) {
        self.imageStackView.subviews.forEach { (view) in
            guard let imageView = view as? UIImageView else { return }
            if imageView.tag == sender.tag {
                imageView.removeFromSuperview()
                self.viewModel.uploadImageDetail[imageView.tag] = nil
            }
        }
        
        sender.removeFromSuperview()
        removeButtons.removeAll { (button) -> Bool in
            return button.tag == sender.tag
        }
        
        self.imageStackViewHeight.constant -= 192
        self.uploadViewHeight.constant -= 192
        self.remarkViewHeight.constant -= 192
        var y = self.imageStackView.frame.origin.y
        for button in removeButtons {
            button.frame.origin.y = (y + 12)
            y += 192
        }
        
        if self.removeButtons.count != 0 {
            self.confirmButton.isEnabled = true
            self.confirmButton.setTitleColor(UIColor.redForDarkFull, for: .normal)
        } else {
            self.confirmButton.isEnabled = false
            self.confirmButton.setTitleColor(UIColor.textSecondaryScorpionGray, for: .normal)
        }
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoWithdrawalTicketBatched {
            Alert.shared.show(nil, Localize.string("withdrawal_cancel_locked"), confirm: {}, cancel: nil)
        } else {
            super.handleErrors(error)
        }
    }
    
}


// MARK: CAMERA EVENT
extension WithdrawalRecordDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension WithdrawalRecordDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusChangeHistories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: RemarkTableViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! RemarkTableViewCell
        cell.setup(history: statusChangeHistories[indexPath.row], httpClient: httpClient)
        cell.toBigImage = {(url, image) in
            if let vc = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController {
                vc.url = url
                vc.thumbnailImage = image
                NavigationManagement.sharedInstance.pushViewController(vc: vc)
            }
        }
        return cell
    }
}
