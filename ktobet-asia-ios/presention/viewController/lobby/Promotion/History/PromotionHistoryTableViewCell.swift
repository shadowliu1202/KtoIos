import UIKit
import RxSwift
import RxCocoa
import SharedBu


class PromotionHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var datelabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var hourGlassImage: UIImageView!
    @IBOutlet weak var expandView: UIView!
    @IBOutlet weak var expandLabel: UILabel!
    @IBOutlet weak var expandImg: UIImageView!
    @IBOutlet weak var detailStackView: UIStackView!
    
    var callBack: (() -> ())?
    var timer: Timer?
    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        detailStackView.removeAllArrangedSubviews()
        stopAnimation()
    }
    
    func config(_ coupon: CouponHistory, tableView: UITableView) {
        datelabel.text = "\(coupon.receiveDate.toDateTimeFormatString()) \(Localize.string("bonus_receive"))"
        typeButton.setTitle(StringMapper.parseBonusTypeString(bonusType: coupon.type), for: .normal)
        typeNameLabel.isHidden = coupon.type != BonusType.product
        typeNameLabel.text = StringMapper.parseProductTypeString(productType: coupon.productType)
        nameLabel.text = coupon.name
        if let issue = coupon.issue, issue != 0 {
            noLabel.text = String(format: Localize.string("bonus_period"), "\(issue)")
        } else {
            noLabel.isHidden = true
        }
        
        statusLabel.text = StringMapper.parse(bonusReceivingStatus: coupon.bonusLockReceivingStatus)
        statusLabel.textColor = Theme.shared.parse(bonusReceivingStatus: coupon.bonusLockReceivingStatus)
        amountLabel.text = coupon.amount.description()
        if coupon.isTurnOverCalculating {
            amountLabel.isHidden = true
            hourGlassImage.isHidden = false
            startAnimation()
        } else {
            amountLabel.isHidden = false
            hourGlassImage.isHidden = true
        }
        
        expandLabel.text = coupon.isExpanded ? Localize.string("common_fold") : Localize.string("common_open")
        expandImg.image = coupon.isExpanded ? UIImage(named: "iconArrowDropUp16") : UIImage(named: "iconArrowDropDown16")
        detailStackView.isHidden = !coupon.isExpanded
        
        let tap = UITapGestureRecognizer()
        expandView.addGestureRecognizer(tap)
        tap.rx.event.bind {(recognizer) in
            coupon.isExpanded.toggle()
            tableView.reloadData()
        }.disposed(by: disposeBag)
        
        setExpandedDetail(coupon)
    }
    
    fileprivate func setExpandedDetail(_ coupon: CouponHistory) {
        setDetailViewRow(title: Localize.string("bonus_historyno"), content: coupon.bonusId)
        setDetailViewRow(title: Localize.string("bonus_historyname"), content: coupon.name)
        setDetailViewRow(title: Localize.string("bonus_historyamount"), content: coupon.amount.description())
        setDetailViewRow(title: Localize.string("bonus_historydate"), content: coupon.receiveDate.toDateTimeFormatString())
        if let turnOverDetail = coupon.turnOverDetail, coupon.hasTurnOver && !coupon.isTurnOverCalculating {
            setDetailViewRow(title: Localize.string("bonus_historytrialbalance"), content: turnOverDetail.balance.description())
            setDetailViewRow(title: Localize.string("bonus_historytrialamount"), content: turnOverDetail.amount.description())
            setDetailViewRow(title: Localize.string("bonus_historytrialrequest"), content: turnOverDetail.request.description())
            setDetailViewRow(title: Localize.string("bonus_historybetmutipler"), content: turnOverDetail.formula)
            setDetailViewRow(title: Localize.string("bonus_turnover_adddeposit"), content: turnOverDetail.turnoverRequestForDeposit.description())
            setDetailViewRow(title: Localize.string("bonus_turnover_total"), content: turnOverDetail.turnoverRequest.description())
            setDetailViewRow(title: Localize.string("bonus_historytrialachieved"), content: turnOverDetail.achieved.description())
            setDetailViewRow(title: Localize.string("bonus_historytrialcompletion"), content: turnOverDetail.percentage.description() + "%")
        }
    }
    
    fileprivate func setDetailViewRow(title: String, content: String) {
        let detailViewRow = PromotionHistoryDetailView()
        detailViewRow.setUp(title: title, content: content)
        detailViewRow.translatesAutoresizingMaskIntoConstraints = false
        detailStackView.addArrangedSubview(detailViewRow)
    }
    
    fileprivate func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { (timer) in
            self.hourGlassImage.rotate()
        }
        
        timer?.fire()
    }
    
    fileprivate func stopAnimation() {
        timer?.invalidate()
    }
}

class PromotionHistoryDetailView: UIView {
    private var titleLbl: UILabel!
    private var contentLbl: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let childStack = UIStackView(frame: .zero)
        childStack.translatesAutoresizingMaskIntoConstraints = false
        childStack.axis = .vertical
        childStack.alignment = .fill
        childStack.distribution = .fill
        self.addSubview(childStack,constraints: .fill())
        titleLbl = UILabel(frame: .zero)
        contentLbl = UILabel(frame: .zero)
        titleLbl.font = UIFont.init(name: "PingFangSC-Regular", size: 14)
        titleLbl.textColor = UIColor.gray9B9B9B
        contentLbl.font = UIFont.init(name: "PingFangSC-Medium", size: 14)
        contentLbl.textColor = UIColor.whitePure
        titleLbl.numberOfLines = 0
        titleLbl.lineBreakMode = .byWordWrapping
        contentLbl.numberOfLines = 0
        contentLbl.lineBreakMode = .byWordWrapping
        childStack.addArrangedSubview(titleLbl)
        childStack.addArrangedSubview(contentLbl)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setUp(title: String, content: String) {
        titleLbl.text = title
        contentLbl.text = content
        titleLbl.sizeToFit()
        contentLbl.sizeToFit()
    }
    
    func getHeight() -> CGFloat {
        return titleLbl.frame.height + contentLbl.frame.height
    }
}

extension CouponHistory {
    private struct AssociatedKeys {
        static var isExpanded = "isExpanded"
    }
    
    var isExpanded: Bool! {
        get {
            guard let isExpanded = objc_getAssociatedObject(self, &AssociatedKeys.isExpanded) as? Bool else {
                return true
            }
            
            return isExpanded
        }
        
        set(value) {
            objc_setAssociatedObject(self, &AssociatedKeys.isExpanded, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
