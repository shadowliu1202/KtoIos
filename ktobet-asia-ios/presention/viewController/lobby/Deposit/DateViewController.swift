import UIKit

class DateViewController: UIViewController {
    static let segueIdentifier = "toDateSegue"
    @IBOutlet fileprivate weak var dateSegment: UISegmentedControl!
    @IBOutlet fileprivate weak var currentDateLabel: UILabel!
    @IBOutlet fileprivate weak var dateView: UIView!
    @IBOutlet fileprivate weak var nextButton: UIButton!
    @IBOutlet fileprivate weak var previousButton: UIButton!
    @IBOutlet var month: UIView!
    
    private lazy var monthSelectView = MonthSelectView(frame: .zero, playerLocale: playerLocaleConfiguration.getSupportLocale())
    
    var conditionCallbck: ((_ dateType: DateType) -> ())?
    var dateType: DateType = .week()
    fileprivate let invalidPeriodLength = 90
    fileprivate var koyomi: Koyomi!
    fileprivate var seletedDate: Date?
    fileprivate var currentSelectedStyle: SelectionMode = .sequence(style: .semicircleEdge)
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    
    private let playerLocaleConfiguration = DI.resolve(PlayerLocaleConfiguration.self)!
    private lazy var dateSegmentTitle = Theme.shared.getSegmentTitleName(by: playerLocaleConfiguration.getSupportLocale())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        month.addSubview(monthSelectView, constraints: .fill())
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        self.setupDateSegmentLabel()
        
        DispatchQueue.main.async {
            let frame = CGRect(x: 0, y : 0, width: self.dateView.frame.width, height: self.dateView.frame.height)
            self.koyomi = Koyomi(frame: frame, sectionSpace: 0, cellSpace: 0, inset: .zero, weekCellHeight: 25)
            self.koyomi.circularViewDiameter = 1.0
            self.koyomi.calendarDelegate = self
            self.koyomi.weeks = (Localize.string("common_sunday"),
                                 Localize.string("common_monday"),
                                 Localize.string("common_tuesday"),
                                 Localize.string("common_wednesday"),
                                 Localize.string("common_thursday"),
                                 Localize.string("common_friday"),
                                 Localize.string("common_saturday"))
            self.koyomi.style = .deepBlack
            self.koyomi.dayPosition = .center
            self.koyomi.selectedStyleColor = UIColor(red: 1.0, green: 213/255, blue: 0, alpha: 1)
            self.koyomi.weekColor = UIColor.yellowFull
            self.koyomi.setWeekFont(fontName: "PingFangSC-Medium", size: 12)
            self.koyomi.setDayFont(fontName: "PingFangSC-Medium", size: 12)
            self.dateView.addSubview(self.koyomi)
            switch self.dateType {
            case .day(let date):
                self.dateSegment.selectedSegmentIndex = 1
                self.seletedDate = date
                let diffMonth = date.betweenTwoMonth(from: Date())
                self.changeMonth(month: .someMonth(Int(diffMonth)))
            case .week:
                self.selectPastSevenDays()
            case .month(let starDate, _):
                self.dateSegment.selectedSegmentIndex = 2
                self.month.isHidden = false
                self.dateView.isHidden = true
                self.monthSelectView.setSelectedDate(starDate.convertdateToUTC())
            }

            self.currentDateLabel.text = Theme.shared.getDatePickerTitleLabel(by: self.playerLocaleConfiguration.getSupportLocale(), self.koyomi)

        }
        
        let titleTextAttributes: [NSAttributedString.Key : Any]? = [.foregroundColor: UIColor.whiteFull, .font: UIFont.init(name: "PingFangSC-Medium", size: Theme.shared.getDateSegmentTitleFontSize(by: self.playerLocaleConfiguration.getSupportLocale()))!]
        dateSegment.setTitleTextAttributes(titleTextAttributes, for: .normal)
        dateSegment.setTitleTextAttributes(titleTextAttributes, for: .selected)
        dateSegment.addTarget(
            self,
            action: #selector(onChange),
            for: .valueChanged)
        month.isHidden = true
        monthSelectView.callback = { [weak self] (starDate, endDate) in
            self?.dateType = .month(fromDate: starDate, toDate: endDate)
        }
    }
    
    private func setupDateSegmentLabel() {
        UILabel.appearance(whenContainedInInstancesOf:[UISegmentedControl.self]).numberOfLines = 2
        var segmentIndex = 0
        for titleName in dateSegmentTitle {
            dateSegment.setTitle(titleName, forSegmentAt: segmentIndex)
            segmentIndex += 1
        }
    }
    
    fileprivate func selectSingleDate(date: Date = Date()) {
        dateSegment.selectedSegmentIndex = 1
        currentSelectedStyle = .single(style: .circle)
        koyomi.selectionMode = currentSelectedStyle
        koyomi.unselectAll()
        koyomi.select(date: date)
        dateType = .day(date)
        koyomi.reloadData()
    }
    
    fileprivate func selectPastSevenDays() {
        dateSegment.selectedSegmentIndex = 0
        currentSelectedStyle = .sequence(style: .semicircleEdge)
        koyomi.selectionMode = currentSelectedStyle
        koyomi.unselectAll()
        koyomi.select(date: Date().getPastSevenDate(), to: Date())
        dateType = .week(fromDate: Date().getPastSevenDate(), toDate: Date())
        koyomi.reloadData()
    }
    
    @IBAction func previous(_ sender: UIButton) {
        changeMonth(month: .previous)
    }
    
    @IBAction func next(_ sender: UIButton) {
        changeMonth(month: .next)
    }
    
    @IBAction func confirm(_ sernder: UIButton) {
        var selectDate: [Date] = []
        koyomi.model.getSelectedDates().forEach { (date) in
            selectDate.append(date.convertdateToUTC())
        }
        
        conditionCallbck?(dateType)
        NavigationManagement.sharedInstance.popViewController()
    }
    
    fileprivate func changeMonth(month: MonthType) {
        let month: MonthType = month
        koyomi.display(in: month)
        switch dateSegment.selectedSegmentIndex {
        case 0:
            selectPastSevenDays()
        case 1:
            selectSingleDate(date: seletedDate ?? Date())
        default:
            break
        }
        
        setNextMonthButton()
        setPreviousMonthButton()
        self.currentDateLabel.text = self.koyomi.currentDateString() + Localize.string("common_month")
    }
    
    fileprivate func isCurrentMonth() -> Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M"
        let date = dateFormatter.date(from: self.koyomi.currentDateString())
        let currentSeletedMonth = calendar.component(.month, from: date!)
        return currentSeletedMonth == currentMonth
    }
    
    fileprivate func setPreviousMonthButton() {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.month = -5
        guard let pastFiveMonthDate = Calendar.current.date(byAdding: dateComponent, to: Date().adding(value: 0, byAdding: .day)) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/M"
        let date = dateFormatter.date(from: self.koyomi.currentDateString())
        let currentSeletedMonth = calendar.component(.month, from: date!)
        if currentSeletedMonth == pastFiveMonthDate.getMonth() {
            previousButton.setImage(UIImage(named: "Chevron Left Disable(24)"), for: .normal)
            previousButton.isEnabled = false
        } else {
            previousButton.setImage(UIImage(named: "Chevron Left(24)"), for: .normal)
            previousButton.isEnabled = true
        }
    }
    
    fileprivate func setNextMonthButton() {
        if isCurrentMonth() {
            nextButton.setImage(UIImage(named: "Chevron Right Disable(24)"), for: .normal)
            nextButton.isEnabled = false
        } else {
            nextButton.setImage(UIImage(named: "Chevron Right(24)"), for: .normal)
            nextButton.isEnabled = true
        }
    }
    
    @objc func onChange(sender: UISegmentedControl) {
        nextButton.setImage(UIImage(named: "Chevron Right Disable(24)"), for: .normal)
        nextButton.isEnabled = false
        previousButton.setImage(UIImage(named: "Chevron Left(24)"), for: .normal)
        previousButton.isEnabled = true
        switch sender.selectedSegmentIndex {
        case 0:
            koyomi.display(in: .current)
            selectPastSevenDays()
            month.isHidden = true
            dateView.isHidden = false
        case 1:
            if !isCurrentMonth() { koyomi.display(in: .current) }
            month.isHidden = true
            dateView.isHidden = false
            selectSingleDate()
        case 2:
            month.isHidden = false
            dateView.isHidden = true
            let currentDate = Date()
            monthSelectView.setSelectedDate(currentDate)
            dateType = .month(fromDate: MonthItem.from(year: Int(currentDate.getYear()), month: Int(currentDate.getMonth())),
                              toDate: MonthItem.end(year: Int(currentDate.getYear()), month: Int(currentDate.getMonth())))
        default:
            break
        }
    }
    
    @objc func close() {
        NavigationManagement.sharedInstance.popViewController()
    }
}

// MARK: - KoyomiDelegate -
extension DateViewController: KoyomiDelegate {
    func koyomi(_ koyomi: Koyomi, didSelect date: Date?, forItemAt indexPath: IndexPath) {
        if let date = date {
            seletedDate = date
            selectSingleDate(date: date)
            dateSegment.selectedSegmentIndex = 1
            print("You Selected: \(date)")
        }
    }
    
    func koyomi(_ koyomi: Koyomi, currentDateString dateString: String) {
        currentDateLabel.text = dateString + Localize.string("common_month")
    }
    
    @objc(koyomi:shouldSelectDates:to:withPeriodLength:)
    func koyomi(_ koyomi: Koyomi, shouldSelectDates date: Date?, to toDate: Date?, withPeriodLength length: Int) -> Bool {
        if length > invalidPeriodLength {
            print("More than \(invalidPeriodLength) days are invalid period.")
            return false
        }
        return true
    }
}
