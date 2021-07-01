import UIKit
import RxSwift
import SharedBu

class AddCryptoAccountViewController: UIViewController {
    static let segueIdentifier = "toCryptoAddAccount"
    @IBOutlet weak var cryptoTypeDropDown: DropDownInputText!
    @IBOutlet weak var accountNameTextField: InputText!
    @IBOutlet weak var accountAddressTextField: InputText!
    @IBOutlet weak var accountNameErrorLabel: UILabel!
    @IBOutlet weak var accountAddressErrorLabel: UILabel!
    @IBOutlet weak var accountAddressView: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var qrCodeButton: UIButton!

    var bankCardCount: Int = 0
    
    fileprivate let viewModel = DI.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate let disposeBag = DisposeBag()
    fileprivate var imagePickerView: ImagePickerViewController!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        accountAddressTextField.rx.observe(UIColor.self, "backgroundColor").bind(to: accountAddressView.rx.backgroundColor).disposed(by: disposeBag)
        let supportCry = Crypto.Companion.init().support()
        supportCry.forEach{ print($0.simpleName) }
        cryptoTypeDropDown.optionArray = supportCry.map{ $0.simpleName }
        cryptoTypeDropDown.setTitle(Localize.string("cps_crypto_currency"))
        accountNameTextField.setTitle(Localize.string("cps_crypto_account_name"))
        accountAddressTextField.setTitle(Localize.string("cps_wallet_address"))
        
        (accountNameTextField.text <-> viewModel.accountName).disposed(by: disposeBag)
        (accountAddressTextField.text <-> viewModel.accountAddress).disposed(by: disposeBag)
        (cryptoTypeDropDown.text <-> viewModel.cryptoType).disposed(by: disposeBag)
        
        let event = viewModel.event()
        event.accountNameValid.subscribe { [weak self] (isValid) in
            guard let isValid = isValid.element, self?.accountNameTextField.isEdited ?? false else { return }
            let message = isValid ? "" : Localize.string("common_field_must_fill")
            self?.accountNameErrorLabel.text = message
            self?.accountNameTextField.showUnderline(!isValid)
        }.disposed(by: disposeBag)
        
        event.accountAddressValid.subscribe { [weak self] (isValid) in
            guard let isValid = isValid.element, self?.accountAddressTextField.isEdited ?? false else { return }
            let message = isValid ? "" : Localize.string("common_field_must_fill")
            self?.accountAddressErrorLabel.text = message
            self?.accountAddressTextField.showUnderline(!isValid)
        }.disposed(by: disposeBag)
        
        event.dataValid.bind(to: submitButton.rx.valid).disposed(by: disposeBag)
        
        submitButton.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            if self.bankCardCount >= 3 {
                Alert.show(Localize.string("common_tip_title_warm"),  String(format: Localize.string("withdrawal_bankcard_add_overlimit"), "3"), confirm: nil, cancel: nil, tintColor: UIColor.red)
            } else {
                self.viewModel.addCryptoBankCard().subscribe(onSuccess: { (data) in
                    Alert.show(Localize.string("profile_safety_verification_title"), Localize.string("cps_security_alert"), confirm: {
                        self.performSegue(withIdentifier: WithdrawalCryptoVerifyViewController.segueIdentifier, sender: data)
                    }, cancel: nil)
                }, onError: { (error) in
                    if (error as? KTOError) == KTOError.EmptyData {
                        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("withdrawal_account_exist"), confirm: nil, cancel: nil, tintColor: UIColor.red)
                    }
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        qrCodeButton.rx.tap.subscribe(onNext: {[weak self] in
            self?.showImagePicker()
        }).disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalCryptoVerifyViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalCryptoVerifyViewController {
                dest.playerCryptoBankCardId = sender as? String
            }
        }
    }
    
    fileprivate func showImagePicker() {
        imagePickerView = UIStoryboard(name: "ImagePicker", bundle: nil).instantiateViewController(withIdentifier: "ImagePickerViewController") as? ImagePickerViewController
        imagePickerView.delegate = self
        imagePickerView.selectedImageLimitCount = 1
        imagePickerView.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
        imagePickerView.isHiddenFooterView = true
        imagePickerView.cameraImage = UIImage(named: "Scan")
        imagePickerView.cameraText = Localize.string("cps_scan")
        imagePickerView.cameraType = .qrCode
        imagePickerView.completion = {[weak self] (images) in
            NavigationManagement.sharedInstance.popViewController()
            if let features = self?.detectQRCode(images.first), !features.isEmpty {
                for case let row as CIQRCodeFeature in features {
                    self?.accountAddressTextField.setContent(row.messageString ?? "")
                    self?.viewModel.accountAddress.accept(row.messageString ?? "")
                    self?.accountAddressTextField.adjustPosition()
                }
            }  else {
                Alert.show(Localize.string("cps_qr_code_read_fail"), Localize.string("cps_qr_code_read_fail_content"), confirm: nil, cancel: nil, tintColor: UIColor.red)

            }
        }
        
        imagePickerView.qrCodeCompletion = {[weak self] (string) in
            if let viewControllers = self?.navigationController?.viewControllers {
                for controller in viewControllers {
                    if controller.isKind(of: AddCryptoAccountViewController.self) {
                        NavigationManagement.sharedInstance.popViewController(nil, vc: controller)
                        NavigationManagement.sharedInstance.viewController = self
                    }
                }
            }

            self?.accountAddressTextField.setContent(string)
            self?.accountAddressTextField.adjustPosition()
        }
        
        NavigationManagement.sharedInstance.pushViewController(vc: imagePickerView)
    }
    
    fileprivate func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
        if let image = image, let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features

        }
        return nil
    }

}

// MARK: CAMERA EVENT
extension AddCryptoAccountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true) {
            NavigationManagement.sharedInstance.popViewController()
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
