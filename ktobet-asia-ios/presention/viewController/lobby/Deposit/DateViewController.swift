import UIKit

class DateViewController: UIViewController {
    static let segueIdentifier = "toDateSegue"
    @IBOutlet fileprivate weak var dateSegment: UISegmentedControl!
    @IBOutlet fileprivate weak var currentDateLabel: UILabel!
    @IBOutlet fileprivate weak var dateView: UIView!
    @IBOutlet fileprivate weak var nextButton: UIButton!
    @IBOutlet fileprivate weak var previousButton: UIButton!
    @IBOutlet var month: MonthSelectView!
    
    var conditionCallbck: ((_ beginDate: Date, _ endDate: Date) -> ())?
    var depositDateType: DateType = .week
    fileprivate let invalidPeriodLength = 90
    fileprivate var koyomi: Koyomi!
    fileprivate var seletedDate: Date?
    fileprivate var currentSelectedStyle: SelectionMode = .sequence(style: .semicircleEdge)
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate var starDate: Date?
    fileprivate var endDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addCloseToBarButtonItem(vc: self, isShowAlert: false, closeAction: {
            self.navigationController?.popViewController(animated: true)
        }, closeTitle: "", closeMessage: "")
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
            self.koyomi.setDayFont(size: 12) .setWeekFont(size: 12)
            self.koyomi.setDayFont(fontName: "PingFangSC-Medium", size: 12)
            self.dateView.addSubview(self.koyomi)
            switch self.depositDateType {
            case .day(let date):
                self.dateSegment.selectedSegmentIndex = 1
                let selectedDate = date.convertDateTIme(format: "yyyy/MM/dd")?.convertdateToUTC() ?? Date()
                self.seletedDate = selectedDate
                let diffMonth = selectedDate.betweenTwoMonth(from: Date())
                self.changeMonth(month: .someMonth(Int(diffMonth)))
            case .week:
                self.selectPastSevenDays()
            case .month(let date):
                let selectedDate = date.convertDateTIme(format: "yyyy/MM/dd")?.convertdateToUTC() ?? Date()
                print(selectedDate)
                self.dateSegment.selectedSegmentIndex = 2
                self.month.isHidden = false
                self.dateView.isHidden = true
                self.month.setSelectedDate(selectedDate)
            }

            self.currentDateLabel.text = self.koyomi.currentDateString() + Localize.string("common_month")
        }
        
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.whiteFull]
        dateSegment.setTitleTextAttributes(titleTextAttributes, for: .normal)
        dateSegment.setTitleTextAttributes(titleTextAttributes, for: .selected)
        dateSegment.addTarget(
            self,
            action: #selector(onChange),
            for: .valueChanged)
        month.isHidden = true
        month.callback = { [weak self] (starDate, endDate) in
            self?.starDate = starDate.convertdateToUTC()
            self?.endDate = endDate.convertdateToUTC()
        }
    }
    
    fileprivate func selectSingleDate(date: Date = Date()) {
        dateSegment.selectedSegmentIndex = 1
        currentSelectedStyle = .single(style: .circle)
        koyomi.selectionMode = currentSelectedStyle
        koyomi.unselectAll()
        koyomi.select(date: date)
        koyomi.reloadData()
    }
    
    fileprivate func selectPastSevenDays() {
        dateSegment.selectedSegmentIndex = 0
        currentSelectedStyle = .sequence(style: .semicircleEdge)
        koyomi.selectionMode = currentSelectedStyle
        koyomi.unselectAll()
        koyomi.select(date: Date().getPastSevenDate().adding(value: -1, byAdding: .day), to: Date())
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
        
        if dateSegment.selectedSegmentIndex != 2 {
            self.starDate = selectDate.last
            self.endDate = selectDate.first
        }
        guard let beginDate = self.starDate, let endDate = self.endDate else { return }
        conditionCallbck?(beginDate, endDate)
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
        switch sender.selectedSegmentIndex {
        case 0:
            if !isCurrentMonth() { koyomi.display(in: .current) }
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
            month.setSelectedDate(currentDate)
            self.starDate = currentDate.startOfMonth
            self.endDate = currentDate.endOfMonth
        default:
            break
        }
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
