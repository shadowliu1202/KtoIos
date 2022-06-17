import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SetBirthdayViewController: LobbyViewController, AuthProfileVerification {
    static let segueIdentifier = "toSetBirthday"
    private var isPickedDate = false
    @IBOutlet weak var birthdayInput: InputText!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var submitBtn: UIButton!
   
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    private var calendarBackground: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        birthdayInput.setIsEdited(false)
        self.submitBtn.isValid = false
    }
    
    private func dataBinding() {
        let tapGesture = UITapGestureRecognizer.init()
        self.birthdayInput.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.subscribe { [weak self] (gesture) in
            self?.popupCalendar()
        }.disposed(by: self.disposeBag)
        viewModel.relayBirthdayDate.compactMap({$0}).map({$0.toDateString()}).bind(onNext: { [weak self] in
            self?.birthdayInput.setContent($0)
            self?.birthdayInput.setNeedsLayout()
        }).disposed(by: disposeBag)
        
        submitBtn.rx.touchUpInside.bind(onNext: { [unowned self] in
            self.submitBtn.isEnabled = false
            let dateStr = self.birthdayInput.textContent.text
            let _ = self.viewModel.modifyBirthday(birthDay: dateStr).subscribe(onCompleted: { [weak self] in
                self?.popThenToastSuccess()
            }, onError: { [weak self] in
                self?.handleErrors($0)
                self?.submitBtn.isEnabled = true
            })
        }).disposed(by: disposeBag)
    }
    
    private func popupCalendar() {
        calendarBackground = UIView(frame: UIWindow.key!.frame)
        calendarBackground.backgroundColor = .black80
        self.view.addSubview(calendarBackground)
        let locale = viewModel.locale
        let dateStr = birthdayInput.textContent.text
        let initDate = dateStr?.toDate(format: "yyy/MM/dd", timeZone: Foundation.TimeZone(abbreviation: "UTC")!) ?? Date.getMinimumAdultBirthday()
        let datePickerPopup = DatePickerPopup(locale: locale, initDate: initDate, self)
        self.view.addSubview(datePickerPopup, constraints: [
            .equal(\.centerXAnchor),
            .equal(\.centerYAnchor),
            .ratioWidth(0.9, equalTo: self.view.widthAnchor),
            .ratioHeight(1, equalTo: datePickerPopup.widthAnchor)
        ])
    }

    override func handleErrors(_ error: Error) {
        if error.isUnauthorized() {
            self.navigateToAuthorization()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToastOnBottom(Localize.string("common_setting_done"), img: UIImage(named: "Success"))
        })
    }
    
    private func validateBirthday(_ date: Date?) {
        let error = viewModel.validateBirthday(date)
        var message = ""
        switch error {
        case .none:
            message = ""
        case .empty:
            message = Localize.string("common_field_must_fill")
        case .notAdult:
            message = Localize.string("profile_birthday_not_adult")
        }
        self.errorLabel.text = message
        self.birthdayInput.showUnderline(message.count > 0)
        self.birthdayInput.setCorner(topCorner: true, bottomCorner: message.count == 0)
        self.submitBtn.isValid = error == .none ? true : false
    }
}

extension SetBirthdayViewController: DatePickerPopupDelegate {
    func didPick(date: Date?) {
        calendarBackground.removeFromSuperview()
        if isPickedDate == false, date != nil {
            isPickedDate = true
        }
        if isPickedDate == true, date == nil { return }
        self.viewModel.relayBirthdayDate.accept(date)
        self.validateBirthday(date)
    }
}
