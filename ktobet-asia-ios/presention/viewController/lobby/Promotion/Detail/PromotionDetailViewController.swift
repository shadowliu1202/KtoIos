import UIKit
import WebKit
import RxSwift
import SharedBu
import RxCocoa


class PromotionDetailViewController: APPViewController {
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var subTypeLabel: UILabel!
    @IBOutlet weak var issueNumberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var expireDateLabel: UILabel!
    @IBOutlet weak var promotionImageView: UIImageView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var getPromotionButton: UIButton!
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var buttonViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewContent: UITextView!
    @IBOutlet weak var textViewRule: UITextView!
    
    var viewModel: PromotionViewModel!
    var item: PromotionVmItem!
    
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        getPromotionButton.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        topBackgroundView.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        textViewContent.linkTextAttributes = [.underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.red, .foregroundColor: UIColor.red]
        textViewRule.linkTextAttributes = [.underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor.red, .foregroundColor: UIColor.red]
        
        textViewContent.delegate = self
        textViewRule.delegate = self
        
        let promotionDetail = Driver.combineLatest(viewModel.getPromotionDetail(id: item.id), viewModel.playerLevel.asDriver(onErrorJustReturn: ""))
        promotionDetail.map{ self.replaceContent(text: $0.content, level: $1) }.drive(textViewContent.rx.attributedText).disposed(by: disposeBag)
        promotionDetail.map{ self.replaceContent(text: $0.rules, level: $1) }.drive(textViewRule.rx.attributedText).disposed(by: disposeBag)
        
        setView(productTypeTitle: item.title,
                productSubType: item.subTitle,
                productName: item.message,
                issueNumber: item.issueNo,
                productTypeDrawable: item.icon,
                promotionAmount: item.displayAmount,
                validPeriod: (item as? BonusCouponItem)?.validPeriod,
                isFull: (item as? PromotionEventItem)?.isAutoUse() ?? false)
        
        getPromotionButton.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            if let bonusCoupon = self.item as? BonusCoupon {
                self.viewModel.requestCouponApplication(bonusCoupon: bonusCoupon)
                    .flatMapCompletable({ (waiting) in
                        return SubUseBonusCoupon.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
                    }).subscribe(onCompleted: { [weak self] in
                        self?.viewModel.fetchData()
                    }, onError: { [weak self] (error) in
                        self?.handleErrors(error)
                    }).disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
    }
    
    private func replaceContent(text: String, level: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        let fontAttribute = [NSAttributedString.Key.font: UIFont(name: "PingFangSC-Regular", size: 14)!,
                             NSAttributedString.Key.foregroundColor: UIColor.textSecondaryScorpionGray,
                             NSAttributedString.Key.paragraphStyle: paragraphStyle]
        
        var attributedString = NSMutableAttributedString(string: text, attributes: fontAttribute)
        replaceParameter(text: &attributedString, parameter: "{date}", value: self.item.displayInformPlayerDate)
        replaceParameter(text: &attributedString, parameter: "{maxbonus}", value: self.item.displayMaxAmount)
        replaceParameter(text: &attributedString, parameter: "{multiple}", value: (self.item as? BonusCouponItem)?.displayBetMultiple ?? "")
        replaceParameter(text: &attributedString, parameter: "{level}", value: self.item.displayLevel ?? level)
        replaceParameter(text: &attributedString, parameter: "{percentage}", value: self.item.displayPercentage)
        replaceParameter(text: &attributedString, parameter: "{mincapital}", value: (self.item as? BonusCouponItem)?.displayMinCapital ?? "")
        replaceBonusTnc(text: &attributedString, parameter: "{bonustnc}", value: Localize.string("bonus_detail_contentrule"))
        return attributedString
    }
    
    private func replaceBonusTnc(text: inout NSMutableAttributedString, parameter: String, value: String) {
        guard let index = text.string.index(of: parameter)?.utf16Offset(in: text.string) else { return }
        replaceParameter(text: &text, parameter: parameter, value: value)
        text.addAttribute(.link, value: "", range: NSRange(location: index, length: value.count))
    }
    
    private func replaceParameter(text: inout NSMutableAttributedString, parameter: String, value: String) {
        guard let index = text.string.index(of: parameter)?.utf16Offset(in: text.string) else { return }
        text.replaceCharacters(in: NSRange(location: index, length: parameter.count), with: NSAttributedString(string: value))
        text.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: index, length: value.count))
        text.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14)!, range: NSRange(location: index, length: value.count))
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func setView(
        productTypeTitle: String,
        productSubType: String,
        productName: String,
        issueNumber: String?,
        productTypeDrawable: String,
        promotionAmount: String,
        validPeriod: ValidPeriod?,
        isFull: Bool = false) {
        typeButton.setTitle(productTypeTitle, for: .normal)
        subTypeLabel.isHidden = productSubType.isEmpty
        subTypeLabel.text = productSubType
        issueNumberLabel.isHidden = issueNumber?.isEmpty ?? true
        issueNumberLabel.text = issueNumber
        nameLabel.text = productName
        amountLabel.text = promotionAmount.replacingOccurrences(of: "\n", with: " ")
        promotionImageView.image = UIImage(named: productTypeDrawable)
        statusImageView.isHidden = !isFull
        
        
        switch item {
        case let bonusItem as BonusCouponItem:
            configureBonusCouponItem(bonusItem)
            let verify = bonusItem.validPeriod.verify(time: Date().convertDateToOffsetDateTime())
            getPromotionButton.alpha = verify ? 1.0 : 0.4
            getPromotionButton.isEnabled = verify
            if let product = bonusItem as? BonusCoupon.Product {
                promotionImageView.image = UIImage(named: getImage(productType: product.productType))
            }
        case let eventItem as PromotionEventItem:
            buttonViewHeight.constant = 0
            getPromotionButton.isHidden = true
            configurePromotionEventItem(eventItem)
            if let product = eventItem as? PromotionEvent.Product {
                promotionImageView.image = UIImage(named: getImage(productType: product.type))
            }
        default:
            break
        }
    }
    
    private func getImage(productType: ProductType) -> String {
        switch productType {
        case .slot:
            return "iconLvSlot48Big"
        case .sbk:
            return "iconLvSportsbook48Big"
        default:
            return ""
        }
    }
    
    private func configureBonusCouponItem(_ bonusCoupon: BonusCouponItem) {
        switch bonusCoupon.validPeriod {
        case let duration as ValidPeriod.Duration:
            startExpireDateDisplayCounter(duration)
        case is ValidPeriod.Always:
            expireDateLabel.isHidden = true
        default:
            break
        }
    }
    
    private func configurePromotionEventItem(_ promotion: PromotionEventItem) {
        let endDate = promotion.expireDate
        CountDownTimer().start(timeInterval: 1, endTime: endDate) {[weak self] index, countDownSeconds, finish in
            self?.setExpireDateText(now: Date(), endDate: endDate)
        }
    }
    
    private func setExpireDateText(now: Date, endDate: Date) {
        let calendar = Calendar.current
        var dayComponent = DateComponents()
        dayComponent.hour = -48
        
        guard let periodEndMinus48 = calendar.date(byAdding: dayComponent, to: endDate) else {
            expireDateLabel.text = ""
            return
        }
        
        let isCurrentDateTimeIn48HoursOfExpireDate = now > periodEndMinus48
        
        if isCurrentDateTimeIn48HoursOfExpireDate {
            let diff = (endDate - now).timeRemainingFormatted()
            expireDateLabel.text = Localize.string("bonus_status_expirydate", diff)
        } else {
            expireDateLabel.text = Localize.string("bonus_status_expirydate", endDate.toDateString())
        }
    }
    
    private func startExpireDateDisplayCounter(_ period: ValidPeriod.Duration) {
        let remainTime = TimeInterval(period.countLeftMilliSeconds()) / 1000
        CountDownTimer().start(timeInterval: 1, duration: remainTime) {[weak self] index, countDownSeconds, finish in
            if !finish {
                let localizedStr = self?.generalPeriodString(now: Date(), period: period)
                self?.expireDateLabel.text = localizedStr
            }
        }
    }
    
    private func generalPeriodString(now: Date, period: ValidPeriod.Duration) -> String {
        var dayComponent = DateComponents()
        dayComponent.hour = -48
        let calendar = Calendar.current
        let periodStartDate = period.start.convertToDate()
        let periodEndDate = period.end.convertToDate()
        
        guard let periodStartMinus48 = calendar.date(byAdding: dayComponent, to: periodStartDate),
              let periodEndMinus48 = calendar.date(byAdding: dayComponent, to: periodEndDate) else {
            return Localize.string("bonus_status_expirydate", "00:00:00")
        }
        
        if now < periodStartMinus48 {
            return Localize.string("bonus_couponnostart", periodStartDate.toDateString())
        } else if now > periodStartMinus48, now < periodStartDate {
            let diff = (periodStartDate - now).timeRemainingFormatted()
            return Localize.string("bonus_couponnostart", diff)
        } else if now > periodStartDate, now < periodEndMinus48 {
            return Localize.string("bonus_status_expirydate", periodEndDate.toDateString())
        } else if now > periodStartDate, now > periodEndMinus48 {
            let diff = abs((now - periodEndDate)).timeRemainingFormatted()
            return Localize.string("bonus_status_expirydate", diff)
        }
        return Localize.string("bonus_status_expirydate", "00:00:00")
    }
}

extension PromotionDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        performSegue(withIdentifier: PromotionRuleTermViewController.segueIdentifier, sender: nil)
        return false
    }
}
