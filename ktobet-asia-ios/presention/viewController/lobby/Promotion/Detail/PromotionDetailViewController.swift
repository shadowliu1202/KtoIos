import UIKit
import WebKit
import RxSwift
import SharedBu


class PromotionDetailViewController: UIViewController {
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
    @IBOutlet weak var contentTemplateWebView: WKWebView!
    @IBOutlet weak var ruleTemplateWebView: WKWebView!
    @IBOutlet weak var contentWebViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ruleWebViewHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonViewHeight: NSLayoutConstraint!
    
    var viewModel: PromotionViewModel!
    var item: PromotionVmItem!
    fileprivate var disposeBag = DisposeBag()
    fileprivate let bonusTnc = "bonustnc"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        getPromotionButton.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        topBackgroundView.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        
        let scaleContentHeaderString = "<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>"
        let fontName = "PingFangSC-Regular"
        let fontSize = 14
        let fontSetting = "<span style=\"font-family: \(fontName);font-size: \(fontSize)\"</span>"
        
        setView(productTypeTitle: item.title,
                productSubType: item.subTitle,
                productName: item.message,
                issueNumber: item.issueNo,
                productTypeDrawable: item.icon,
                promotionAmount: item.displayAmount,
                validPeriod: (item as? BonusCouponItem)?.validPeriod,
                isFull: (item as? PromotionEventItem)?.isAutoUse() ?? false)
        
        contentTemplateWebView.scrollView.isScrollEnabled = false
        ruleTemplateWebView.scrollView.isScrollEnabled = false
        contentTemplateWebView.navigationDelegate = self
        ruleTemplateWebView.navigationDelegate = self
        Observable.combineLatest(viewModel.getPromotionDetail(promotionId: item.id).asObservable(), viewModel.playerLevel.asObservable())
            .map({[weak self] (promotionDescriptions, level) -> (PromotionDescriptions, String) in
                guard let self = self else { return (promotionDescriptions, level) }
                var content = promotionDescriptions.content.replacingOccurrences(of: "rgb(255, 255, 255)", with: "rgb(0, 0, 0)")
                content = content.replacingOccurrences(of: "{date}", with: self.item.displayInformPlayerDate)
                content = content.replacingOccurrences(of: "{maxbonus}", with: self.item.displayMaxAmount)
                content = content.replacingOccurrences(of: "{multiple}", with: (self.item as? BonusCouponItem)?.displayBetMultiple ?? "")
                content = content.replacingOccurrences(of: "{level}", with: self.item.displayLevel ?? level)
                content = content.replacingOccurrences(of: "{percentage}", with: self.item.displayPercentage)
                content = content.replacingOccurrences(of: "{mincapital}", with: (self.item as? BonusCouponItem)?.displayMinCapital ?? "" )
                content = content.replacingOccurrences(of: "{\(self.bonusTnc)}", with: "<a href=\"bonustnc\" style=\"color:red;\">\(Localize.string("license_promotion_terms"))</a>" )
                let ruleContent = promotionDescriptions.rules.replacingOccurrences(of: "{\(self.bonusTnc)}", with: "<a href=\"bonustnc\" style=\"color:red;\">\(Localize.string("license_promotion_terms"))</a>" )
                return (PromotionDescriptions.init(content: content, rules: ruleContent), level)
            })
            .subscribe {[weak self] (promotionDescriptions, level) in
                self?.contentTemplateWebView.loadHTMLString(fontSetting + scaleContentHeaderString + promotionDescriptions.content, baseURL: nil)
                self?.ruleTemplateWebView.loadHTMLString(fontSetting + scaleContentHeaderString + promotionDescriptions.rules, baseURL: nil)
            } onError: { error in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)
        
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
    
    private func getBonusLevel(bonusCoupon: BonusCoupon) -> String {
        if let depositReturnLevel = bonusCoupon as? BonusCoupon.DepositReturnLevel {
            return depositReturnLevel.level.description
        } else {
            return "0"
        }
    }
    
    private func getPercentage(bonusCoupon: BonusCoupon) -> String {
        switch bonusCoupon {
        case let freeBet as BonusCoupon.FreeBet:
            return freeBet.percentage.description
        case let depositReturnLevel as BonusCoupon.DepositReturnLevel:
            return depositReturnLevel.percentage.description
        case let depositReturnCustomize as BonusCoupon.DepositReturnCustomize:
            return depositReturnCustomize.percentage.description
        case let rebate as BonusCoupon.Rebate:
            return rebate.percentage.description
        default:
            return ""
        }
    }
}

extension PromotionDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.isLoading == false {
            webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { [weak self] (result, error) in
                if let height = result as? CGFloat {
                    if webView == self?.contentTemplateWebView {
                        self?.contentWebViewHeight.constant = height
                    } else {
                        self?.ruleWebViewHeight.constant = height
                    }
                }
            })
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated {
            if let url = navigationAction.request.url?.absoluteString, url == bonusTnc {
                print(url)
                performSegue(withIdentifier: PromotionRuleTermViewController.segueIdentifier, sender: nil)
            }
            
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
