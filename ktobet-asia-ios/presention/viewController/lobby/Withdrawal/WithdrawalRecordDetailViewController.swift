import UIKit
import RxSwift
import share_bu

class WithdrawalRecordDetailViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalRecordSegue"
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

    var detailRecord: WithdrawalRecord!
    fileprivate var viewModel = DI.resolve(WithdrawalViewModel.self)!
    fileprivate var uploadViewModel = DI.resolve(UploadPhotoViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var imagePicker = OpalImagePickerController()
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    fileprivate var removeButtons: [UIButton] = []
    fileprivate var isOverImageLimit = false
    fileprivate var imageIndex = 0
    fileprivate var imageUploadInex = 0

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        dataBinding()
        eventHandler()
        initUI()
        openPhoto()
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        DispatchQueue.main.async {
            self.titleNameLabel.text = Localize.string("withdrawal_detail_title")
            self.amountTitleLabel.text = Localize.string("common_transactionamount")
            self.statusTitleLabel.text = Localize.string("common_status")
            self.applytimeTitleLabel.text = Localize.string("common_applytime")
            self.withdrawalIdTitleLabel.text = Localize.string("withdrawal_ticketnumber")
            self.remarkTitleLabel.text = Localize.string("common_remark")
            self.uploadTitleLabel.text = Localize.string("common_upload_file")
            self.clickUploadLabel.text = Localize.string("common_click_to_upload")
            self.uploadLimitTiplabel.text = Localize.string("common_photo_upload_limit")
            self.confirmButton.setTitle(Localize.string("common_submit"), for: .normal)
            self.confirmButton.isEnabled = false
            self.confirmButton.layer.borderWidth = 1
            self.confirmButton.layer.borderColor = UIColor.textSecondaryScorpionGray.cgColor
            self.cancelButton.setTitle(Localize.string("withdrawal_cancel"), for: .normal)
            self.amountView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
            self.amountView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.applyTimeView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.applyTimeView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.remarkView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.activityIndicator)
            self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        }
    }
    
    fileprivate func dataBinding() {
        self.remarkTableview.delegate = nil
        self.remarkTableview.dataSource = nil
        startActivityIndicator()
        viewModel.getWithdrawalRecordDetail(transactionId: detailRecord.displayId, transactionTransactionType: detailRecord.transactionTransactionType).subscribe {[weak self] (data) in
            guard let self = self else { return }
            let statusChangeHistoriesObservalbe = Observable.from(optional: data.statusChangeHistories)
            statusChangeHistoriesObservalbe.bind(to: self.remarkTableview.rx.items(cellIdentifier: String(describing: RemarkTableViewCell.self), cellType: RemarkTableViewCell.self)) {[weak self] (index, d, cell) in
                cell.setup(history: d)
                cell.toBigImage = {[weak self] (image) in
                    self?.performSegue(withIdentifier: ImageViewController.segueIdentifier, sender: image)
                }
            }.disposed(by: self.disposeBag)

            statusChangeHistoriesObservalbe.subscribeOn(MainScheduler.instance)
                .subscribe {[weak self] _ in
                self?.updateUI(data: data)
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: self.disposeBag)
            self.stopActivityIndicator()
        } onError: { (error) in
            self.handleUnknownError(error)
            self.stopActivityIndicator()
        }.disposed(by: disposeBag)
    }
    
    fileprivate func updateUI(data: WithdrawalRecordDetail) {
        DispatchQueue.main.async {
            self.applytimeLabel.text = data.record.createDate.formatDateToStringToSecond()
            self.amountLabel.text = data.record.cashAmount.amount.currencyFormatWithoutSymbol(precision: 2)
            self.withdrawalIdLabel.text = data.record.displayId
            self.statusLabel.text = StringMapper.sharedInstance.parse(data.record.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: true)
            self.statusDateLabel.text = data.updatedDate.formatDateToStringToSecond()
            self.uploadViewHeight.constant = 0
            self.statusViewHeight.constant = 77
            self.statusDateLabel.isHidden = false
            self.confirmButton.isHidden = true
            self.cancelButton.isHidden = true
            self.uploadView.isHidden = true
            if data.record.transactionStatus == TransactionStatus.floating {
                self.uploadViewHeight.constant = 171
                self.confirmButton.isHidden = false
                self.cancelButton.isHidden = false
                self.uploadView.isHidden = false
            }

            if data.record.transactionStatus == TransactionStatus.pending {
                self.statusDateLabel.isHidden = true
                self.statusDateLabel.text = ""
                self.statusViewHeight.constant = 60
                self.cancelButton.isHidden = false
                self.buttonStackView.removeArrangedSubview(self.confirmButton)
            }

            self.statusView.layoutIfNeeded()
            self.remarkTableview.layoutIfNeeded()
            self.remarkTableViewHeight.constant = self.remarkTableview.contentSize.height
            self.remarkTableview.layoutIfNeeded()
            self.remarkViewHeight.constant = self.remarkTableViewHeight.constant + self.uploadViewHeight.constant + 60
            self.remarkView.layoutIfNeeded()
            if data.record.transactionStatus != .floating {
                self.remarkView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
            }
        }
    }
    
    fileprivate func eventHandler() {
        self.confirmButton.rx.tap.subscribe(onNext: {[weak self] in
            self?.cofirmUploadImage()
        }).disposed(by: self.disposeBag)
        self.cancelButton.rx.tap.subscribe(onNext: {[weak self] in
            self?.cancelWithdrawal()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func cofirmUploadImage() {
        self.startActivityIndicator()
        self.viewModel.bindingImageWithWithdrawalRecord(displayId: self.detailRecord.displayId, transactionId: EnumMapper.Companion.init().convertTransactionStatus(transactionStatus: .pending), portalImages: self.viewModel.uploadImageDetail.map { $0.value.portalImage }).subscribe {
            self.dataBinding()
            self.stopActivityIndicator()
        } onError: { (error) in
            self.handleUnknownError(error)
            self.stopActivityIndicator()
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func cancelWithdrawal() {
        self.startActivityIndicator()
        self.viewModel.cancelWithdrawal(ticketId: detailRecord.displayId).subscribe {[weak self] in
            self?.dataBinding()
            self?.stopActivityIndicator()
        } onError: { (error) in
            self.handleUnknownError(error)
            self.stopActivityIndicator()
        }.disposed(by: disposeBag)
    }
    
    fileprivate func openPhoto() {
        let tap = UITapGestureRecognizer.init()
        self.uploadClickView.addGestureRecognizer(tap)
        tap.rx.event.subscribe {[weak self] (gesture) in
            self?.showImagePicker()
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func showImagePicker() {
        let currentSelectedImageCount = self.imageStackView.subviews.count
        if currentSelectedImageCount >= 3 {
            Alert.show("", Localize.string("common_photo_upload_count_limit"), confirm: nil, cancel: nil)
        }
        
        self.imagePicker = OpalImagePickerController()
        self.imagePicker.maximumSelectionsAllowed = 3 - currentSelectedImageCount
        self.imagePicker.maximumImageSizeLimit = WithdrawalViewModel.imageLimitSize
        self.imagePicker.showCamera = { [weak self] in
            self?.imagePicker.dismiss(animated: true, completion: nil)
            let cameraPicer = UIImagePickerController()
            cameraPicer.sourceType = .camera
            cameraPicer.delegate = self
            self?.present(cameraPicer, animated: true)
        }
        
        presentOpalImagePickerController(imagePicker, animated: true,
                                         select: { (assets) in
                                            self.imagePicker.dismiss(animated: true) {
                                                assets.forEach {
                                                    let image = $0.convertAssetToImage()
                                                    if image.isOverImageLimitSize(imageLimitSize: WithdrawalViewModel.imageLimitSize) {
                                                        self.showUploadLimitSizeAlert()
                                                    } else {
                                                        self.startActivityIndicator()
                                                        self.uploadImage(image: image)
                                                    }
                                                }
                                            }
                                         }, cancel: { })
    }
    
    fileprivate func uploadImage(image: UIImage) {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        uploadViewModel.uploadImage(imageData: imageData).subscribe { (result) in
            self.viewModel.uploadImageDetail[self.imageUploadInex] = result
            self.confirmButton.isEnabled = true
            self.confirmButton.setTitleColor(UIColor.redForDarkFull, for: .normal)
            self.imageUploadInex += 1
            self.addImageToUI(image: image)
            self.stopActivityIndicator()
        } onError: { (error) in
            self.stopActivityIndicator()
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func addImageToUI(image: UIImage) {
        let y = self.imageStackView.frame.origin.y + CGFloat(self.imageStackView.subviews.count * 192)
        let imageView = UIImageView()
        imageView.tag = imageIndex
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
        removeButton.tag = imageIndex
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
        imageIndex += 1
    }
    
    fileprivate func removeImage(sender: UIButton) {
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
    
    fileprivate func showUploadLimitSizeAlert() {
        DispatchQueue.main.async {
            Alert.show(Localize.string("common_tip_title_warm"), Localize.string("deposit_execeed_limitation"), confirm: nil, cancel: nil, tintColor: UIColor.red)
        }
    }
    
    fileprivate func startActivityIndicator() {
        DispatchQueue.main.async {
            UIApplication.shared.beginIgnoringInteractionEvents()
            self.activityIndicator.startAnimating()
        }
    }
    
    fileprivate func stopActivityIndicator() {
        DispatchQueue.main.async {
            UIApplication.shared.endIgnoringInteractionEvents()
            self.activityIndicator.stopAnimating()
        }
    }
}


// MARK: CAMERA EVENT
extension WithdrawalRecordDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                if image.isOverImageLimitSize(imageLimitSize: WithdrawalViewModel.imageLimitSize) {
                    self.showUploadLimitSizeAlert()
                } else {
                    self.startActivityIndicator()
                    self.uploadImage(image: image)
                }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        showImagePicker()
    }
}
