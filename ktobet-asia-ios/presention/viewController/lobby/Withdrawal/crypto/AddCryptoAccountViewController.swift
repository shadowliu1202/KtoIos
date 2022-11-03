import UIKit
import RxSwift
import SharedBu
import SwiftUI

class AddCryptoAccountViewController: LobbyViewController {
    static let segueIdentifier = "toCryptoAddAccount"
    @IBOutlet weak var cryptoTypeDropDown: DropDownInputText!
    @IBOutlet weak var cryptoNetworkDropDown: DropDownInputText!
    @IBOutlet weak var accountNameTextField: InputText!
    @IBOutlet weak var accountAddressTextField: InputText!
    @IBOutlet weak var accountNameErrorLabel: UILabel!
    @IBOutlet weak var accountAddressErrorLabel: UILabel!
    @IBOutlet weak var accountAddressView: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var qrCodeButton: UIButton!

    var bankCardCount: Int = 0
    
    fileprivate let viewModel = Injectable.resolve(ManageCryptoBankCardViewModel.self)!
    private let cryptoViewModel = Injectable.resolve(CryptoViewModel.self)!
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var imagePickerView: ImagePickerViewController!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("", tag: "KTO-876")
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        accountAddressTextField.rx.observe(UIColor.self, "backgroundColor").bind(to: accountAddressView.rx.backgroundColor).disposed(by: disposeBag)
        
        cryptoViewModel.supportCryptoTypes.subscribe(onSuccess: { [unowned self] in
            let supportCrypto = $0.map({$0.name})
            self.cryptoTypeDropDown.optionArray = supportCrypto
            self.cryptoTypeDropDown.setTitle(Localize.string("cps_crypto_currency"))
            self.viewModel.selectedCryptoType.accept(supportCrypto.first ?? "")
        }).disposed(by: disposeBag)
        (cryptoTypeDropDown.text <-> viewModel.selectedCryptoType).disposed(by: disposeBag)
        
        viewModel.supportCryptoNetwork.subscribe(onNext: { [unowned self] (cryptoNetworkArrays) in
            self.cryptoNetworkDropDown.optionArray = cryptoNetworkArrays.map { $0.name }
        }).disposed(by: disposeBag)
        cryptoNetworkDropDown.setTitle(Localize.string("cps_crypto_network"))
        (cryptoNetworkDropDown.text <-> viewModel.selectedCryptoNetwork).disposed(by: disposeBag)
        
        accountNameTextField.setTitle(Localize.string("cps_crypto_account_name"))
        accountAddressTextField.setTitle(Localize.string("cps_wallet_address"))
        accountNameTextField.maxLength = ManageCryptoBankCardViewModel.accountNameMaxLength
        accountNameTextField.setCorner(topCorner: true, bottomCorner: true)
        accountAddressTextField.setCorner(topCorner: true, bottomCorner: true)
        accountAddressTextField.maxLength = ManageCryptoBankCardViewModel.accountAddressMaxLength
        
        (accountNameTextField.text <-> viewModel.accountName).disposed(by: disposeBag)
        (accountAddressTextField.text <-> viewModel.accountAddress).disposed(by: disposeBag)
                
        viewModel.accountName.accept(Localize.string("cps_default_bank_card_name") + "\(bankCardCount + 1)")
        
        let event = viewModel.event()
        event.accountNameValid.subscribe { [weak self] (isValid) in
            guard let isValid = isValid.element, self?.accountNameTextField.isEdited ?? false else { return }
            let message = isValid ? "" : Localize.string("common_field_must_fill")
            self?.accountNameErrorLabel.text = message
            self?.accountNameTextField.showUnderline(!isValid)
            self?.accountNameTextField.setCorner(topCorner: true, bottomCorner: isValid)
        }.disposed(by: disposeBag)


        event.accountAddressValid.subscribe { [weak self] (validError) in
            guard let self = self else { return }
            guard let validError = validError.element, self.accountAddressTextField.isEdited else { return }
            var message = ""
            var isValid = false
            switch validError {
            case .empty:
                message = Localize.string("common_field_must_fill")
            case .regex:
                switch self.viewModel.stringToCryptoNetwork() {
                case .erc20:
                    message = Localize.string("cps_erc20_address_error")
                case .trc20:
                    message = Localize.string("cps_trc20_address_error")
                default:
                    message = Localize.string("common_invalid")
                }
            default:
                isValid = true
            }
            
            self.accountAddressErrorLabel.text = message
            self.accountAddressTextField.showUnderline(!isValid)
            self.accountAddressTextField.setCorner(topCorner: true, bottomCorner: isValid)
            self.accountAddressView.setViewCorner(topCorner: true, bottomCorner: isValid)
            if !isValid {
                self.accountAddressView.addBorder(.bottom, color: UIColor.orangeFull)
            } else {
                self.accountAddressView.removeBorder(.bottom)
            }
        }.disposed(by: disposeBag)
        
        event.dataValid.bind(to: submitButton.rx.valid).disposed(by: disposeBag)
        
        submitButton.rx.tap.subscribe(onNext: {[weak self] in
            Logger.shared.info("submitButton.rx.tap", tag: "KTO-876")
            guard let `self` = self else { return }
            if self.bankCardCount >= Settings.init().WITHDRAWAL_CRYPTO_BANK_CARD_LIMIT {
                Alert.shared.show(Localize.string("common_tip_title_warm"),  String(format: Localize.string("withdrawal_bankcard_add_overlimit"), Settings.init().WITHDRAWAL_CRYPTO_BANK_CARD_LIMIT), confirm: nil, cancel: nil, tintColor: UIColor.red)
            } else {
                Logger.shared.info("viewModel.addCryptoBankCard()", tag: "KTO-876")
                self.viewModel.addCryptoBankCard().subscribe(onSuccess: { (data) in
                    Alert.shared.show(Localize.string("profile_safety_verification_title"), Localize.string("cps_security_alert"), confirm: {
                        self.performSegue(withIdentifier: WithdrawalCryptoVerifyViewController.segueIdentifier, sender: data)
                    }, cancel: nil)
                }, onFailure: self.handleErrors).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        qrCodeButton.rx.tap.subscribe(onNext: {[weak self] in
            self?.showImagePicker()
        }).disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoWithdrawalAccountExist {
            Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("cps_bank_card_exist"), confirm: nil, cancel: nil, tintColor: UIColor.red)
        } else {
            super.handleErrors(error)
        }
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
                Alert.shared.show(Localize.string("cps_qr_code_read_fail"), Localize.string("cps_qr_code_read_fail_content"), confirm: nil, cancel: nil, tintColor: UIColor.red)

            }
        }
        
        imagePickerView.qrCodeCompletion = {[weak self] (string) in
            if let viewControllers = self?.navigationController?.viewControllers {
                for controller in viewControllers {
                    if controller.isKind(of: AddCryptoAccountViewController.self) {
                        NavigationManagement.sharedInstance.popViewController(nil, to: controller)
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
