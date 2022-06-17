import UIKit
import RxSwift

class OfflineMessageViewController: CommonViewController {
    var barButtonItems: [UIBarButtonItem] = []
    
    @IBOutlet weak var emailInputText: InputText!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var messageContent: UITextView!
    @IBOutlet weak var completeBtn: UIButton!
    @IBOutlet weak var emailInputTextHetght: NSLayoutConstraint!
    @IBOutlet weak var emailInputTextTopMargin: NSLayoutConstraint!
    
    private var viewModel = DI.resolve(SurveyViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        emailInputText.setTitle(Localize.string("common_email"))
        emailInputText.setCorner(topCorner: true, bottomCorner: true)
        emailInputText.setKeyboardType(.emailAddress)
        messageContent.delegate = self
        messageContent.text = Localize.string("customerservice_offline_survey_hint")
        messageContent.textColor = UIColor.textPrimaryDustyGray
        messageContent.textContainer.lineFragmentPadding = 0
        messageContent.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
    }
    
    private func dataBinding() {
        viewModel.isGuest.subscribe(onSuccess: { [weak self] in
            if $0 == false {
                self?.emailInputTextHetght.constant = 0
                self?.emailInputTextTopMargin.constant = 18
            }
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
        (emailInputText.textContent.rx.text <-> viewModel.offlineSurveyAccount).disposed(by: disposeBag)
        viewModel.accontValid.subscribe(onNext: { [weak self] in
            let message = self?.transferError($0)
            self?.emailErrorLabel.text = message
            self?.emailInputText.showUnderline(message?.count ?? 0 > 0)
            self?.emailInputText.setCorner(topCorner: true, bottomCorner: message?.count == 0)
        }).disposed(by: disposeBag)
        viewModel.isOfflineSurveyValid.bind(to: completeBtn.rx.isValid).disposed(by: disposeBag)
    }
    
    func transferError(_ error: ValidError) -> String {
        switch error {
        case .length, .regex:
            return Localize.string("common_error_email_format")
        case .empty:
            return Localize.string("common_field_must_fill")
        case .none:
            return ""
        }
    }
    
    @IBAction func pressSend(_ sender: Any) {
        self.completeBtn.isEnabled = false
        viewModel.createOfflineSurvey().subscribe(onCompleted: { [weak self] in
            self?.notifySurveySentSuccessfully()
        }, onError: { [weak self] in
            self?.completeBtn.isEnabled = true
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    private func notifySurveySentSuccessfully() {
        Alert.show(Localize.string("customerservice_offline_survey_confirm_title"),
                   Localize.string("customerservice_offline_survey_confirm_content"),
                   confirm: { CustomService.close() }, cancel: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
}

extension OfflineMessageViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        CustomService.close()
    }
}

extension OfflineMessageViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.textPrimaryDustyGray {
            textView.text = nil
            textView.textColor = UIColor.whiteFull
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel.offlineSurveyContent.accept(textView.text)
        if textView.text.isEmpty {
            textView.text = Localize.string("customerservice_offline_survey_hint")
            textView.textColor = UIColor.textPrimaryDustyGray
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel.offlineSurveyContent.accept(textView.text)
    }
}
