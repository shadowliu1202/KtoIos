import UIKit
import RxSwift
import RxCocoa
import SwiftUI

enum PromotionFilter {
    case all
    case manual
    case freeBet
    case depositReturn
    case product
    case rebate
    var tagId: Int {
        switch self {
        case .all:
            return 100
        case .manual:
            return 101
        case .freeBet:
            return 102
        case .depositReturn:
            return 103
        case .product:
            return 104
        case .rebate:
            return 105
        }
    }
    var name: String {
        switch self {
        case .all:
            return Localize.string("bonus_bonustype_all_count")
        case .manual:
            return Localize.string("bonus_bonustype_manual_count")
        case .freeBet:
            return Localize.string("bonus_bonustype_1_count")
        case .depositReturn:
            return Localize.string("bonus_bonustype_2_count")
        case .product:
            return Localize.string("bonus_bonustype_3_count")
        case .rebate:
            return Localize.string("bonus_bonustype_4_count")
        }
    }
    
    enum Product: Int {
        case Sport = 200
        case Slot
        case Casino
        case Numbergame
        case Arcade
        
        var name: String {
            switch self {
            case .Sport:
                return Localize.string("common_sportsbook")
            case .Slot:
                return Localize.string("common_slot")
            case .Casino:
                return Localize.string("common_casino")
            case .Numbergame:
                return Localize.string("common_keno")
            case .Arcade:
                return Localize.string("common_arcade")
            }
        }
        var iconId: Int {
            return self.rawValue + 100
        }
    }
}

class PromotionFilterDropDwon: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.init(name: "PingFangSC-Medium", size: 12)
        label.textColor = UIColor.textPrimaryDustyGray
        return label
    }()
    private lazy var arrowIcon: UIImageView = {
        return UIImageView(image: UIImage(named: "promotionArrowDropDown"))
    }()
    private lazy var button: UIButton = {
        let btn = UIButton()
        return btn
    }()
    private lazy var backgroundGestureView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    private var isExpand = false {
        didSet {
            if isExpand {
                arrowIcon.image = UIImage(named: "promotionArrowDropUp")
                titleLabel.textColor = UIColor.yellowFull
                showList()
            } else {
                arrowIcon.image = UIImage(named: "promotionArrowDropDown")
                titleLabel.textColor = UIColor.textPrimaryDustyGray
                hideList()
            }
        }
    }
    private var isProductListExpand = false
    private var once = true
    private var parentController: UIViewController?
    private var pointToParent = CGPoint(x: 0, y: 0)
    private let mainViewHeight: CGFloat = 129
    private let mainViewPlusProductViewHeight: CGFloat = 240
    
    private(set) var mainView: UIView!
    private var mainStackView: UIStackView!
    private lazy var line: UIView! = {
        let line = UIView(frame: .zero)
        line.backgroundColor = .textSecondaryScorpionGray
        return line
    }()
    private var bottomStackView: UIStackView?
    private(set) var selectedText: String? {
        didSet {
            self.titleLabel.text = selectedText
        }
    }
    fileprivate(set) var selected: PromotionTag? {
        didSet {
            self.selectedText = selected?.name
        }
    }
    private var disposeBag = DisposeBag()
    private weak var timer: Timer?
    var filterTags: [String] = []
    var tags: [PromotionTag] = [] {
        didSet {
            selected = tags.first(where: {$0.isSelected})
        }
    }
    lazy var productTags: [PromotionProductTag] = [PromotionProductTag(isSelected: true, filter: .Sport),
                                                   PromotionProductTag(isSelected: true, filter: .Slot),
                                                   PromotionProductTag(isSelected: true, filter: .Casino),
                                                   PromotionProductTag(isSelected: true, filter: .Numbergame),
                                                   PromotionProductTag(isSelected: true, filter: .Arcade)]
    var clickHandler: ((PromotionTag?, [PromotionProductTag]) -> ())?
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupUI()
        addGesture()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func setupUI() {
        self.backgroundColor = UIColor.backgroundListCodGray2
        button.addTarget(self, action: #selector(touchAction), for: .touchUpInside)
        self.addBorder(.top, color: .textSecondaryScorpionGray)
        self.addBorder(.bottom, color: .textSecondaryScorpionGray)
    }
    
    private func addGesture() {
        let gesture =  UITapGestureRecognizer(target: self, action: #selector(touchAction))
        self.backgroundGestureView.addGestureRecognizer(gesture)
    }
    
    @objc private func touchAction(_ sender: UIButton) {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(debounceAction), userInfo: nil, repeats: false)
        timer = nextTimer
    }
    
    @objc private func debounceAction(_ sender: UIButton) {
        isExpand.toggle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupConstrains()
    }
    
    private func setupConstrains () {
        guard once else { return }
        self.addSubview(titleLabel, constraints: [
            .constraint(.equal, \.heightAnchor, length: 16),
            .constraint(.equal, \.leadingAnchor, offset: 30),
            .equal(\.centerYAnchor)
        ])
        self.addSubview(arrowIcon)
        arrowIcon.constrain(to: titleLabel, constraints: [
            .equal(\.leadingAnchor, \.trailingAnchor, offset: 4),
            .equal(\.centerYAnchor)
        ])
        self.addSubview(button, constraints: [
            .constraint(.equal, \.leadingAnchor, offset: 30),
            .constraint(.equal, \.topAnchor, offset: 0),
            .constraint(.equal, \.bottomAnchor, offset: 0)
        ])
        button.constrain(to: arrowIcon, constraints: [
            .equal(\.trailingAnchor, \.trailingAnchor, offset:0)
        ])
        once = false
    }
    
    private func showList() {
        if parentController == nil {
            parentController = self.parentViewController
        }
        backgroundGestureView.frame = parentController?.view.frame ?? backgroundGestureView.frame
        pointToParent = getConvertedPoint(self, baseView: parentController?.view)
        parentController?.view.addSubview(backgroundGestureView)
        mainView = UIView(frame: CGRect(x: pointToParent.x ,
                                        y: pointToParent.y + self.frame.height ,
                                        width: self.frame.width,
                                        height: self.frame.height))

        mainView.alpha = 0
        mainView.backgroundColor = self.backgroundColor
        mainStackView = UIStackView(frame: .zero)
        mainView.addSubview(mainStackView, constraints: [.constraint(.equal, \.trailingAnchor, offset: -30),
                                                         .constraint(.equal, \.leadingAnchor, offset: 30),
                                                         .constraint(.equal, \.topAnchor, offset: 24)])
        addBtnTags(stackView: mainStackView, data: tags)
        if case .product = self.selected?.filter {
            self.isProductListExpand = true
            self.setupProductListConstrains(with: productTags)
        }
        parentController?.view.addSubview(mainView)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: [.curveLinear, .allowUserInteraction, .beginFromCurrentState],
                       animations: { () -> Void in
                        var height = self.mainViewHeight
                        if case .product = self.selected?.filter {
                            height = self.mainViewPlusProductViewHeight
                        }
                        self.mainView.frame = CGRect(x: self.pointToParent.x,
                                                     y: self.pointToParent.y + self.frame.height,
                                                     width: self.frame.width,
                                                     height: height)
                        self.mainView.alpha = 1
                       }, completion: nil)
    }
    
    private func hideList() {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: [.curveLinear, .allowUserInteraction, .beginFromCurrentState],
                       animations: { () -> Void in
                        if case .product = self.selected?.filter {
                            self.removeProductList()
                        }
                        self.mainStackView.removeAllArrangedSubviews()
                        self.mainStackView.removeFromSuperview()
                        self.backgroundGestureView.removeFromSuperview()
                        self.mainView.frame = CGRect(x: self.pointToParent.x,
                                                     y: self.pointToParent.y + self.frame.height,
                                                     width: self.frame.width,
                                                     height: 0)
                       }, completion: { (didFinish) -> Void in
                        self.mainView.removeFromSuperview()
                       })
    }
    
    private func setupProductListConstrains(with tags: [PromotionProductTag]) {
        mainView.addSubview(line, constraints: [.constraint(.equal, \.trailingAnchor, offset: -30),
                                                .constraint(.equal, \.leadingAnchor, offset: 30),
                                                .equal(\.heightAnchor, length: 0.5)])
        line.constrain(to: self.mainStackView, constraints: [.equal(\.topAnchor, \.bottomAnchor, offset: 15.5)])
        bottomStackView = UIStackView(frame: .zero)
        mainView.addSubview(bottomStackView!, constraints: [.constraint(.equal, \.trailingAnchor, offset: -30),
                                                            .constraint(.equal, \.leadingAnchor, offset: 30)])
        bottomStackView!.constrain(to: line, constraints: [.equal(\.topAnchor, \.bottomAnchor, offset: 16)])
        addBtnProductTags(stackView: self.bottomStackView!, data: tags)
    }
    
    private func removeProductList() {
        self.line.removeFromSuperview()
        self.bottomStackView?.removeAllArrangedSubviews()
        self.bottomStackView?.removeFromSuperview()
    }
    
    private func showProductList(tags: [PromotionProductTag]) {
        bottomStackView?.alpha = 0
        self.setupProductListConstrains(with: tags)
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: [.curveLinear, .allowUserInteraction],
                       animations: { () -> Void in
                        self.mainView.frame = CGRect(x: self.pointToParent.x,
                                                     y: self.pointToParent.y + self.frame.height,
                                                     width: self.frame.width,
                                                     height: self.mainViewPlusProductViewHeight)
                        self.bottomStackView?.alpha = 1
                       }, completion: nil)
    }
    
    private func hideProductList() {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.1,
                       options: [.curveLinear, .allowUserInteraction],
                       animations: { () -> Void in
                        self.removeProductList()
                        self.mainView.frame = CGRect(x: self.pointToParent.x,
                                                     y: self.pointToParent.y + self.frame.height,
                                                     width: self.frame.width,
                                                     height: self.mainViewHeight)
                       }, completion: nil)
    }
    
    private func getConvertedPoint(_ targetView: UIView, baseView: UIView?) -> CGPoint {
        var pnt = CGPoint(x: targetView.frame.origin.x, y: targetView.frame.origin.y)
        if nil == targetView.superview{
            return pnt
        }
        var superView = targetView.superview
        while superView != baseView{
            pnt = superView!.convert(pnt, to: superView!.superview)
            if nil == superView!.superview{
                break
            }else{
                superView = superView!.superview
            }
        }
        return superView!.convert(pnt, to: baseView)
    }
    
    private func addBtnTags(stackView: UIStackView, data: [PromotionTag]) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        
        var childStack: UIStackView?
        for i in 0..<data.count {
            if i % 3 == 0 {
                childStack = UIStackView(frame: .zero)
                childStack!.translatesAutoresizingMaskIntoConstraints = false
                childStack!.axis = .horizontal
                childStack!.alignment = .fill
                childStack!.distribution = .fillEqually
                childStack!.spacing = 25
                stackView.addArrangedSubview(childStack!)
            }
            let button = UIButton(frame: frame)
            data[i].rxName.bind(to: button.rx.title()).disposed(by: disposeBag)
            button.titleLabel?.font =  UIFont(name: "PingFangSC-Regular", size: 12)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            button.sizeToFit()
            button.layer.cornerRadius = 2
            button.layer.masksToBounds = true
            setTagHighlight(with: button, data[i].isSelected)
            button.tag = tags[i].tagId
            button.addTarget(self, action: #selector(pressFirstLayerTag(_:)), for: .touchUpInside)
            childStack?.addArrangedSubview(button)
        }
    }
    
    private func addBtnProductTags(stackView: UIStackView, data: [PromotionProductTag]) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        
        var childStack: UIStackView?
        for i in 0..<data.count {
            if i % 3 == 0 {
                childStack = UIStackView(frame: .zero)
                childStack!.translatesAutoresizingMaskIntoConstraints = false
                childStack!.axis = .horizontal
                childStack!.alignment = .fill
                childStack!.distribution = .fillEqually
                childStack!.spacing = 25
                stackView.addArrangedSubview(childStack!)
            }
            let contain = UIView(frame: .zero)
            let button = UIButton(frame: frame)
            button.setTitle("\(data[i].name)", for: .normal)
            button.titleLabel?.font =  UIFont(name: "PingFangSC-Medium", size: 12)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            button.sizeToFit()
            button.titleLabel?.numberOfLines = 0
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            button.layer.cornerRadius = 2
            button.layer.masksToBounds = true
            button.backgroundColor = .inputBaseMineShaftGray
            setProductTagHighlight(with: button, data[i].isSelected)
            button.tag = productTags[i].tagId
            button.addTarget(self, action: #selector(pressSecondLayerTag(_:)), for: .touchUpInside)
            contain.addSubview(button, constraints: .fill())
            let icon = UIImageView.init(image: UIImage(named: "promotionTick"))
            contain.addSubview(icon, constraints: [.constraint(.equal, \.leadingAnchor, offset: 0),
                                                   .constraint(.equal, \.topAnchor, offset: 0),
                                                   .equal(\.widthAnchor, length: 13),
                                                   .equal(\.heightAnchor, length: 12)])
            icon.layer.cornerRadius = 2
            icon.layer.masksToBounds = true
            icon.tag = productTags[i].iconTagId
            setProductTickHighlight(with: icon, data[i].isSelected)
            childStack?.addArrangedSubview(contain)
        }
        let remainder = data.count % 3
        if remainder > 0, let lastView = stackView.subviews.last, let childStack = lastView as? UIStackView {
            for _ in 0..<(3-remainder) {
                let button = UIButton(frame: frame)
                childStack.addArrangedSubview(button)
            }
        }
    }
    
    private func setTagHighlight(with btn: UIButton, _ isHighlight: Bool) {
        if isHighlight {
            btn.backgroundColor = .yellowFull
            btn.setTitleColor(UIColor.black_two, for: .normal)
        } else {
            btn.backgroundColor = .inputBaseMineShaftGray
            btn.setTitleColor(UIColor.textPrimaryDustyGray, for: .normal)
        }
    }
    
    private func setProductTagHighlight(with btn: UIButton, _ isHighlight: Bool) {
        if isHighlight {
            btn.borderWidth = 1.0
            btn.bordersColor = .yellowFull
            btn.setTitleColor(.yellowFull, for: .normal)
            button.titleLabel?.font =  UIFont(name: "PingFangSC-Medium", size: 12)
        } else {
            btn.borderWidth = 0.0
            btn.bordersColor = .inputBaseMineShaftGray
            btn.setTitleColor(.textPrimaryDustyGray, for: .normal)
            button.titleLabel?.font =  UIFont(name: "PingFangSC-Regular", size: 12)
        }
    }
    
    private func setProductTickHighlight(with icon: UIImageView, _ isHighlight: Bool) {
        icon.isHidden = !isHighlight
    }
    
    @objc func pressFirstLayerTag(_ sender: UIButton) {
        tags.forEach({ (promotionTag) in
            if let btn = findPromotionButton(by: promotionTag.tagId) {
                setTagHighlight(with: btn, promotionTag.tagId == sender.tag)
                promotionTag.isSelected = promotionTag.tagId == sender.tag
                if promotionTag.tagId == sender.tag {
                    self.selected = promotionTag
                }
            }
        })
        self.selectedText = sender.title(for: .normal)
        if case .product = self.selected?.filter {
            if !isProductListExpand {
                isProductListExpand = true
                showProductList(tags: productTags)
            }
        } else {
            isProductListExpand = false
            hideProductList()
        }
        clickHandler?(selected, productTags)
    }
    
    @objc func pressSecondLayerTag(_ sender: UIButton) {
        if let productTag = productTags.first(where: {$0.tagId == sender.tag}) {
            if productTags.filter({$0.isSelected}).count == 1, productTag.isSelected {
                return
            }
            productTag.isSelected.toggle()
            if let btn = findProductButton(by: productTag.tagId) {
                setProductTagHighlight(with: btn, productTag.isSelected)
            }
            if let tick = findProductTickIcon(by: productTag.iconTagId) {
                setProductTickHighlight(with: tick, productTag.isSelected)
            }
        }
        clickHandler?(selected, productTags)
    }
    
    private func findPromotionButton(by id: Int) -> UIButton? {
        let btn = mainStackView?.viewWithTag(id) as? UIButton
        return btn
    }
    
    private func findProductButton(by id: Int) -> UIButton? {
        let btn = bottomStackView?.viewWithTag(id) as? UIButton
        return btn
    }
    
    private func findProductTickIcon(by id: Int) -> UIImageView? {
        let btn = bottomStackView?.viewWithTag(id) as? UIImageView
        return btn
    }
    
    func updateDropDwonTag(_ filters: [(PromotionFilter, Int)]) {
        filters.forEach({ (tuple) in
            let (filter, count) = tuple
            let promotionTag = self.tags.first(where: { $0.filter == filter})
            promotionTag?.updateCount(count)
            if promotionTag?.tagId == self.selected?.tagId {
                self.selectedText = promotionTag?.name
            }
        })
    }
}

class PromotionTag: Equatable {
    var tagId: Int
    private(set) var name: String = "" {
        didSet {
            rxName.accept(name)
        }
    }
    var rxName = BehaviorRelay<String>(value: "")
    var isSelected: Bool
    private(set) var count: Int
    private(set) var filter: PromotionFilter

    init(isSelected: Bool, filter: PromotionFilter, count: Int) {
        self.tagId = filter.tagId
        self.isSelected = isSelected
        self.filter = filter
        self.count = count
        defer {
            self.name = String(format: filter.name, "\(count)")
        }
    }
    
    fileprivate func updateCount(_ count: Int) {
        self.name = String(format: filter.name, "\(count)")
    }
    
    static func == (lhs: PromotionTag, rhs: PromotionTag) -> Bool {
        return lhs.tagId == rhs.tagId
    }
}

class PromotionProductTag: Equatable {
    var tagId: Int
    var iconTagId: Int
    var name: String
    var isSelected: Bool
    private(set) var filter: PromotionFilter.Product
    
    init(isSelected: Bool, filter: PromotionFilter.Product) {
        self.tagId = filter.rawValue
        self.iconTagId = filter.iconId
        self.isSelected = isSelected
        self.name = filter.name
        self.filter = filter
    }
    
    static func == (lhs: PromotionProductTag, rhs: PromotionProductTag) -> Bool {
        return lhs.tagId == rhs.tagId && lhs.isSelected == rhs.isSelected
    }
}

fileprivate struct PromotionFilterDropDwonRepresent: UIViewRepresentable {
    
    typealias UIViewType = PromotionFilterDropDwon
    
    func makeUIView(context: Context) -> UIViewType {
        let view = PromotionFilterDropDwon()
        view.selected = PromotionTag(isSelected: true, filter: .all, count: 10)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
}

fileprivate struct ContentView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                PromotionFilterDropDwonRepresent().frame(width: UIScreen.main.bounds.size.width, height: 48, alignment: .center)
                Spacer()
            }
            Spacer()
        }
        .background(Color(UIColor.white))
    }
}

struct PromotionFilterDropDwon_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
                .previewDisplayName("iPhone SE")
        }
    }
}
