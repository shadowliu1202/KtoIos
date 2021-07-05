import UIKit
import SharedBu
import RxSwift
import Photos

class DepositRecordDetailViewController: UIViewController {
    static let segueIdentifier = "toDepositRecordSegue"
    @IBOutlet private weak var titleNameLabel: UILabel!
    @IBOutlet private weak var amountTitleLabel: UILabel!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var applytimeTitleLabel: UILabel!
    @IBOutlet private weak var depositIdTitleLabel: UILabel!
    @IBOutlet private weak var uploadTitleLabel: UILabel!
    @IBOutlet private weak var remarkTitleLabel: UILabel!
    
    @IBOutlet private weak var remarkTableview: UITableView!
    
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var statusDateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var applytimeLabel: UILabel!
    @IBOutlet private weak var depositIdLabel: UILabel!
    
    @IBOutlet private weak var uploadView: UIView!
    @IBOutlet private weak var amountView: UIView!
    @IBOutlet private weak var applyTimeView: UIView!
    @IBOutlet private weak var remarkView: UIView!
    @IBOutlet private weak var uploadClickView: UIView!
    @IBOutlet private weak var clickUploadLabel: UILabel!
    @IBOutlet private weak var uploadLimitTiplabel: UILabel!
    
    @IBOutlet private weak var uploadViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var remarkViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var remarkTableViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var imageStackViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var statusViewHeight: NSLayoutConstraint!
    
    @IBOutlet private weak var imageStackView: UIStackView!
    @IBOutlet private weak var scrollview: UIScrollView!
    
    @IBOutlet private weak var confrimButton: UIButton!
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    var detailRecord: DepositRecord!
    
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate var uploadViewModel = DI.resolve(UploadPhotoViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var removeButtons: [UIButton] = []
    fileprivate var imageIndex = 0
    fileprivate var imageUploadInex = 0
    fileprivate var imagePickerView: ImagePickerViewController!
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        dataBinding()
        initUI()
    }
    
    // MARK: BUTTON ACTION
    @IBAction func confirm(_ sender: Any) {
        startActivityIndicator(activityIndicator: activityIndicator)
        viewModel.bindingImageWithDepositRecord(displayId: detailRecord.displayId, transactionId: EnumMapper.Companion.init().convertTransactionStatus(transactionStatus: .pending), portalImages: viewModel.uploadImageDetail.map { $0.value.portalImage }).subscribe {
            self.dataBinding()
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
        } onError: { (error) in
            self.handleUnknownError(error)
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
        }.disposed(by: disposeBag)
    }
    
    @objc func openPhoto(_ sender: UITapGestureRecognizer? = nil) {
        showImagePicker()
    }
    
    @objc private func removeImage(sender: UIButton) {
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
        
        self.confrimButton.isValid = self.removeButtons.count != 0
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        DispatchQueue.main.async {
            self.scrollview.isHidden = true
            self.titleNameLabel.text = Localize.string("deposit_detail_title")
            self.amountTitleLabel.text = Localize.string("common_transactionamount")
            self.statusTitleLabel.text = Localize.string("common_status")
            self.applytimeTitleLabel.text = Localize.string("common_applytime")
            self.depositIdTitleLabel.text = Localize.string("deposit_ticketnumber")
            self.remarkTitleLabel.text = Localize.string("common_remark")
            self.uploadTitleLabel.text = Localize.string("common_upload_file")
            self.clickUploadLabel.text = Localize.string("common_click_to_upload")
            self.uploadLimitTiplabel.text = Localize.string("common_photo_upload_limit")
            self.confrimButton.setTitle(Localize.string("common_submit"), for: .normal)
            self.confrimButton.isValid = false
            self.amountView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
            self.amountView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.applyTimeView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.applyTimeView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            self.remarkView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2, width: self.view.frame.width - 60)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.openPhoto(_:)))
            self.uploadClickView.addGestureRecognizer(tap)
            self.activityIndicator.center = self.view.center
            self.view.addSubview(self.activityIndicator)
        }
    }
    
    fileprivate func showImagePicker() {
        let currentSelectedImageCount = self.imageStackView.subviews.count
        if currentSelectedImageCount >= DepositViewModel.selectedImageCountLimit {
            Alert.show("", String(format: Localize.string("common_photo_upload_limit_reached"), "\(DepositViewModel.selectedImageCountLimit)"), confirm: nil, cancel: nil)
        }
        
        imagePickerView = UIStoryboard(name: "ImagePicker", bundle: nil).instantiateViewController(withIdentifier: "ImagePickerViewController") as? ImagePickerViewController
        imagePickerView.delegate = self
        imagePickerView.imageLimitMBSize = DepositViewModel.imageMBSizeLimit
        imagePickerView.selectedImageLimitCount = DepositViewModel.selectedImageCountLimit - currentSelectedImageCount
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
            toastView.show(on: view, statusTip: String(format: Localize.string("common_photo_upload_limit_count"), String(DepositViewModel.selectedImageCountLimit - currentSelectedImageCount)), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageSizeLimitAlert = {(view) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_execeed_limitation"), img: UIImage(named: "Failed"))
        }
        imagePickerView.showImageFormatInvalidAlert = {view in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))
            toastView.show(on: view, statusTip: Localize.string("deposit_file_format_invalid"), img: UIImage(named: "Failed"))
        }
        
        NavigationManagement.sharedInstance.pushViewController(vc: imagePickerView)
    }
    
    fileprivate func addImageToUI(image: UIImage) {
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
        removeButton.addTarget(self, action: #selector(removeImage), for: .touchUpInside)
        uploadView.addSubview(removeButton)
        removeButtons.append(removeButton)
    }
    
    fileprivate func uploadImage(image: UIImage, count: Int) {
        let imageData = image.jpegData(compressionQuality: 1.0)!
        uploadViewModel.uploadImage(imageData: imageData).subscribe { (result) in
            self.viewModel.uploadImageDetail[self.imageUploadInex] = result
            self.confrimButton.isValid = true
            self.addImageToUI(image: image)
            self.imageUploadInex += 1
            self.imageIndex += 1
            if count == self.imageIndex {
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            }
        } onError: { (error) in
            self.handleUnknownError(error)
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func updateUI(data: DepositDetail.General) {
        self.scrollview.isHidden = false
        self.applytimeLabel.text = data.createdDate.formatDateToStringToSecond()
        self.amountLabel.text = data.requestAmount.displayAmount
        self.depositIdLabel.text = data.displayId
        self.statusViewHeight.constant = 77
        self.statusLabel.text = StringMapper.sharedInstance.parse(data.status, isPendingHold: data.isPendingHold, ignorePendingHold: true)
        if data.status != TransactionStatus.floating {
            self.uploadView.isHidden = true
            self.uploadViewHeight.constant = 0
            self.confrimButton.isHidden = true
        }
        
        if data.status == TransactionStatus.pending {
            self.statusDateLabel.text = ""
            self.statusViewHeight.constant = 60
        }
        
        self.remarkTableview.layoutIfNeeded()
        self.remarkTableViewHeight.constant = self.remarkTableview.contentSize.height
        self.remarkTableview.layoutIfNeeded()
        self.remarkViewHeight.constant = self.remarkTableViewHeight.constant + self.uploadViewHeight.constant + 60
        self.remarkView.layoutIfNeeded()
        if data.status != .floating {
            self.remarkView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
        }
    }
    
    fileprivate func dataBinding() {
        self.remarkTableview.delegate = nil
        self.remarkTableview.dataSource = nil
        viewModel.getDepositRecordDetail(transactionId: detailRecord.displayId).subscribe {[weak self] (data) in
            guard let self = self, let generalData = data as? DepositDetail.General else { return }
            self.statusDateLabel.text = generalData.updatedDate.formatDateToStringToSecond()
            let statusChangeHistoriesObservalbe = Observable.from(optional: generalData.statusChangeHistories)
            statusChangeHistoriesObservalbe.bind(to: self.remarkTableview.rx.items(cellIdentifier: String(describing: RemarkTableViewCell.self), cellType: RemarkTableViewCell.self)) { index, d, cell in
                cell.setup(history: d)
                cell.toBigImage = {[weak self] (url, image) in
                    self?.performSegue(withIdentifier: ImageViewController.segueIdentifier, sender: (url, image))
                }
            }.disposed(by: self.disposeBag)
            
            statusChangeHistoriesObservalbe.subscribeOn(MainScheduler.instance)
                .subscribe { (depositTypes) in
                    self.updateUI(data: generalData)
                } onError: { (error) in
                    self.handleUnknownError(error)
                }.disposed(by: self.disposeBag)
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ImageViewController.segueIdentifier {
            if let dest = segue.destination as? ImageViewController, let tuple = sender as? (String, UIImage) {
                dest.url = tuple.0
                dest.thumbnailImage = tuple.1
            }
        }
    }
    
}

// MARK: CAMERA EVENT
extension DepositRecordDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
