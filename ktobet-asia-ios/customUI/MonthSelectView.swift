import UIKit
import RxSwift
import RxCocoa

private let reuseIdentifier = "MonthCollectionViewCell"
private let displayLimit = 6

class MonthSelectView: UIView {

    @IBOutlet var yearHeadView: UIView!
    @IBOutlet var leftBtn: UIButton!
    @IBOutlet var rightBtn: UIButton!
    @IBOutlet var centerLabel: UILabel!
    var callback: ((_ startDate: Date, _ endDate: Date) -> ())?
    private lazy var disposeBag = DisposeBag()
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(UINib(nibName: "MonthCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        cv.backgroundColor = UIColor.black_two
        return cv
    }()
    
    var currentSource: [[MonthItem]] = []
    var sourcePrevious: [[MonthItem]]?
    var sourceNow: [[MonthItem]]?
    lazy var currentDate = Date()
    lazy var currentYear = Calendar.current.component(.year, from: currentDate)
    lazy var currentMonth = Calendar.current.component(.month, from: currentDate)
    
    enum SourceType {
        case Previous
        case Now
    }
    private var sourceType = SourceType.Now {
        didSet {
            guard hasPrevious else { return }
            switch self.sourceType {
            case SourceType.Now:
                self.leftBtn(enable: true)
                self.rightBtn(enable: false)
            case SourceType.Previous:
                self.leftBtn(enable: false)
                self.rightBtn(enable: true)
            }
        }
    }
    private var hasPrevious = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        calculate()
        setupBinding()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
        calculate()
        setupBinding()
    }
    
    private func setupUI() {
        loadXib()
        leftBtn(enable: false)
        rightBtn(enable: false)
        centerLabel.text = "\(currentYear)"
        addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: yearHeadView.bottomAnchor, constant: 18).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    private func leftBtn(enable: Bool) {
        leftBtn.isEnabled = enable
        var iconNmae: String = ""
        switch enable {
        case true:
            iconNmae = "Chevron Left(24)"
        default:
            iconNmae = "Chevron Left Disable(24)"
        }
        leftBtn.setImage(UIImage(named: iconNmae), for: .normal)
    }
    private func rightBtn(enable: Bool) {
        rightBtn.isEnabled = enable
        var iconNmae: String = ""
        switch enable {
        case true:
            iconNmae = "Chevron Right(24)"
        default:
            iconNmae = "Chevron Right Disable(24)"
        }
        rightBtn.setImage(UIImage(named: iconNmae), for: .normal)
    }
    private func calculate() {
        if currentMonth < displayLimit {
            hasPrevious = true
            leftBtn(enable: true)
            initPreviosSource(enableCount: displayLimit-currentMonth)
        }
        var items = [[MonthItem]](repeating: [], count: 3)
        for section in 0...2 {
            for row in 1...4 {
                let month = 4*section + row
                let index = month - 1
                var isEnable = false
                if currentMonth <= displayLimit {
                    isEnable = index < currentMonth
                } else {
                    let diff = currentMonth - displayLimit
                    if case diff..<currentMonth = index {
                        isEnable = true
                    }
                }
                items[section].append(MonthItem(currentYear, month, isEnable: isEnable))
            }
        }
        currentSource = items
        sourceNow = items
    }
    
    private func initPreviosSource(enableCount: Int) {
        var items = [[MonthItem]](repeating: [], count: 3)
        for section in 0...2 {
            for row in 1...4 {
                let month = 4*section + row
                let index = month - 1
                let isEnable = index >= (12 - enableCount) ? true : false
                items[section].append(MonthItem(currentYear-1, month, isEnable: isEnable))
            }
        }
        sourcePrevious = items
    }
    
    func setupBinding() {
        leftBtn.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else {return}
            self.centerLabel.text = "\(self.currentYear-1)"
            self.sourceType = .Previous
            self.currentSource = self.sourcePrevious!
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)
        rightBtn.rx.touchUpInside.subscribe(onNext: {[weak self] _ in
            guard let `self` = self else {return}
            self.centerLabel.text = "\(self.currentYear)"
            self.sourceType = .Now
            self.currentSource = self.sourceNow!
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    private func loadXib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "MonthSelectView", bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        addSubview(xibView!)
        xibView?.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
        NSLayoutConstraint.activate(attributes.map {
            NSLayoutConstraint(item: xibView!, attribute: $0, relatedBy: .equal, toItem: xibView!.superview, attribute: $0, multiplier: 1, constant: 0)
        })
    }

    func setSelectedDate(_ startDate: Date) {
        for i in 0..<currentSource.count {
            for j in 0..<currentSource[i].count {
                sourcePrevious?[i][j].isSelected = false
                sourceNow![i][j].isSelected = false
                if sourcePrevious != nil, (sourcePrevious![i][j].startDate...sourcePrevious![i][j].endDate).contains(startDate) {
                    sourcePrevious![i][j].isSelected = true
                }
                if sourceNow != nil, (sourceNow![i][j].startDate...sourceNow![i][j].endDate).contains(startDate) {
                    sourceNow![i][j].isSelected = true
                }
            }
        }
        
        if startDate.getYear() == currentYear {
            self.sourceType = .Now
            self.currentSource = self.sourceNow!
        } else {
            self.sourceType = .Previous
            if let source = self.sourcePrevious {
                self.currentSource = source
            }
        }
        
        centerLabel.text = "\(startDate.getYear())"
        self.collectionView.reloadData()
    }
}

extension MonthSelectView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return currentSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSource[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MonthCollectionViewCell
        var item = currentSource[indexPath.section][indexPath.row]
        cell.config(item.title, isEnable: item.isEnable, isSelected: item.isSelected) { (pressedEvent, disposeBag) in
            pressedEvent.subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.toggle(indexPath)
                self.collectionView.reloadData()
                self.callback?(item.startDate, item.endDate)
            }).disposed(by: disposeBag)
        }
        return cell
    }
    
    private func toggle(_ indexPath: IndexPath) {
        for i in 0..<currentSource.count {
            for j in 0..<currentSource[i].count {
                if currentSource[i][j].isSelected {
                    currentSource[i][j].isSelected.toggle()
                }
                if sourcePrevious != nil, sourcePrevious![i][j].isSelected {
                    sourcePrevious![i][j].isSelected.toggle()
                }
                if sourceNow != nil, sourceNow![i][j].isSelected {
                    sourceNow![i][j].isSelected.toggle()
                }
            }
        }
        self.currentSource[indexPath.section][indexPath.row].isSelected.toggle()
        switch sourceType {
        case .Now:
            self.sourceNow = self.currentSource
        case .Previous:
            self.sourcePrevious = self.currentSource
        }
    }
}

extension MonthSelectView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.size.width/4
        let height = collectionView.frame.size.height/3
        return CGSize(width: width, height: height)
    }
}

struct MonthItem {
    private var year: Int
    private var month: Int
    var title: String {
        return "\(month)\(Localize.string("common_month"))"
    }
    let calendar = Calendar(identifier: .gregorian)
    lazy var startDate: Date = self.from(year: self.year,month: self.month)
    lazy var endDate: Date = self.end(year: self.year, month: self.month)
    private(set) var isEnable = false
    var isSelected = false
    
    init(_ year: Int, _ month: Int, isEnable: Bool, isSelected: Bool = false) {
        self.year = year
        self.month = month
        self.isEnable = isEnable
        self.isSelected = isSelected
    }
    
    private func from(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.timeZone = TimeZone(abbreviation: "UTC")!
        components.year = year
        components.month = month
        return calendar.date(from: components)!
    }
    
    private func end(year: Int, month: Int) -> Date {
        return calendar.date(byAdding: DateComponents(month: 1, second: -1), to: self.from(year: year, month: month))!
    }
}
