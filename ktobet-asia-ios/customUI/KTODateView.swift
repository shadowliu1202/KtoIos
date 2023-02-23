import UIKit
import RxSwift


class KTODateView: UIView {
    @IBOutlet private weak var dateLabel: UILabel!
    
    var callBackCondition: ((_ dateBegin: Date?, _ dateEnd: Date?, _ dateType: DateType) -> ())?
    var currentSelectedDateType: DateType = .week()
    
    private weak var parentController: UIViewController?
    private var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
        setupUI()
    }
    
    private func loadXib(){
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "KTODateView", bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        addSubview(xibView)
        xibView.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
        NSLayoutConstraint.activate(attributes.map {
            NSLayoutConstraint(item: xibView, attribute: $0, relatedBy: .equal, toItem: xibView.superview, attribute: $0, multiplier: 1, constant: 0)
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if parentController == nil{
            parentController = self.parentViewController
        }
    }
    
    private func setupUI() {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.gray9B9B9B.cgColor
        let tap = UITapGestureRecognizer.init()
        self.addGestureRecognizer(tap)
        tap.rx.event.subscribe {[weak self] (gesture) in
            self?.goToDateVC()
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func goToDateVC() {
        let storyboard = UIStoryboard(name: "Date", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DateConditionViewController") as! DateViewController
        vc.conditionCallback = {[weak self] (dateType) in
            DispatchQueue.main.async {
                self?.currentSelectedDateType = dateType
                let dateBegin: Date?
                let dateEnd: Date?
                switch dateType {
                case .day(let day):
                    self?.dateLabel.text = day.toMonthDayString()
                    dateBegin = day
                    dateEnd = day
                case .week(let fromDate, let toDate):
                    self?.dateLabel.text = Localize.string("common_last7day")
                    dateBegin = fromDate
                    dateEnd = toDate
                case .month(let fromDate, let toDate):
                    dateBegin = fromDate
                    dateEnd = toDate
                    self?.dateLabel.text = dateBegin?.toYearMonthString()
                }
                
                self?.callBackCondition?(dateBegin, dateEnd, dateType)
            }
        }
        
        vc.dateType = self.currentSelectedDateType
        NavigationManagement.sharedInstance.pushViewController(vc: vc)
    }
}
