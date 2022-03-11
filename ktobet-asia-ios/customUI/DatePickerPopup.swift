import UIKit

protocol DatePickerPopupDelegate: AnyObject {
    func didPick(date: Date?)
}

class DatePickerPopup: UIView {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate: DatePickerPopupDelegate? = nil
    
    var xibView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadXib()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    convenience init(locale: Locale,
                     initDate: Date? = Date(),
                     maximumDate: Date? = Date(),
                     _ delegate: DatePickerPopupDelegate) {
        self.init(frame: CGRect.zero)
        self.delegate = delegate
        self.datePicker.locale = locale
        self.datePicker.setDate(initDate ?? Date(), animated: false)
        self.datePicker.maximumDate = maximumDate
        self.datePicker.minimumDate = "1900/01/01".toDate(format: "yyyy/MM/dd", timeZone: TimeZone(abbreviation: "UTC")!)
        self.alpha = 0.0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }
    
    func loadXib() {
        xibView = loadNib()
        addSubview(xibView, constraints: .fill())
    }
    
    @IBAction func cancelPressed(_ sender: UIButton) {
        disappearAndReturn(date: nil)
    }
    
    @IBAction func okPressed(_ sender: UIButton) {
        disappearAndReturn(date: datePicker.date)
    }
    
    private func disappearAndReturn(date: Date?) {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0.0
        } completion: { (_) in
            self.removeFromSuperview()
            self.delegate?.didPick(date: date)
        }
    }
}

