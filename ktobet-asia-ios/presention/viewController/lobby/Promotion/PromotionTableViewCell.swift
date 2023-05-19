import RxCocoa
import RxSwift
import SharedBu
import UIKit

let TopMargin: CGFloat = 6.0
let BottomMargin: CGFloat = 6.0
let BtnGetCouponHeight: CGFloat = 28.0
let IssueLabelHeight: CGFloat = 16.0
let TimerLabelHeight: CGFloat = 16.0

class PromotionTableViewCell: UITableViewCell {
  @IBOutlet weak var stamp: UIView!
  @IBOutlet weak var stampIcon: UIImageView!
  @IBOutlet weak var issueLabel: UILabel!
  @IBOutlet weak var issueLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var amountPrefixLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var subTagLabel: UILabel!
  @IBOutlet weak var subTagLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var backupLabel: UILabel!
  @IBOutlet weak var backupLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var msgLabel: UILabel!
  @IBOutlet weak var msgLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var btnGetCoupon: UIButton!
  @IBOutlet weak var btnGetCouponHeight: NSLayoutConstraint!
  @IBOutlet weak var timerLabel: UILabel!
  @IBOutlet weak var timerLabelHeight: NSLayoutConstraint!
  @IBOutlet weak var halfCircleBorderStack: UIStackView!
  @IBOutlet weak var watermarkIcon: UIImageView!

  var timer: CountDownTimer?
  var refreshCallback: (() -> Void)?
  private var once = false

  func refreshHandler(_ callback: (() -> Void)? = nil) -> PromotionTableViewCell {
    self.refreshCallback = callback
    return self
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    once = false
    resetUI()
    self.timer?.stop()
  }

  private func resetUI() {
    self.halfCircleBorderStack.removeAllArrangedSubviews()
    issueLabelHeight.constant = IssueLabelHeight
    timerLabelHeight.constant = TimerLabelHeight
    amountPrefixLabel.text = nil
    timerLabel.text = nil
    btnGetCouponHeight.constant = 0
    btnGetCoupon.isHidden = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if once == false {
      once = true
      addStampBorder()
    }
  }

  private func addStampBorder() {
    stamp.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
    let n = (self.frame.height - TopMargin - BottomMargin) / 10
    for _ in 0..<1 {
      let paddingView = UIView()
      paddingView.backgroundColor = UIColor.clear
      paddingView.setContentHuggingPriority(.defaultLow, for: .vertical)
      self.halfCircleBorderStack.addArrangedSubview(paddingView)
    }
    let halfCircleStack = UIStackView(frame: .zero)
    halfCircleStack.axis = .vertical
    halfCircleStack.alignment = .fill
    halfCircleStack.distribution = .fillEqually
    halfCircleStack.spacing = 2
    for _ in 0..<Int(n) {
      let circleView = UIView()
      circleView.layer.cornerRadius = 4
      circleView.layer.masksToBounds = true
      circleView.backgroundColor = UIColor.greyScaleDefault
      halfCircleStack.addArrangedSubview(circleView)
    }
    self.halfCircleBorderStack.addArrangedSubview(halfCircleStack)
    for _ in 0..<1 {
      let paddingView = UIView()
      paddingView.backgroundColor = UIColor.clear
      paddingView.setContentHuggingPriority(.defaultLow, for: .vertical)
      self.halfCircleBorderStack.addArrangedSubview(paddingView)
    }
  }

  func setData(_ item: PromotionVmItem) {
    self.selectionStyle = .none
    issueLabel.text = item.issueNo
    if item.issueNo.isEmpty {
      issueLabelHeight.constant = 0.0
    }
    let splitAmount = item.displayAmount.split(separator: "\n")
    if splitAmount.count == 2 {
      amountPrefixLabel.text = String(splitAmount.first ?? "")
    }
    amountLabel.text = String(splitAmount.last ?? "")
    tagLabel.text = item.title
    configureSubTagLabel(item.subTitle)
    msgLabel.text = item.message
    msgLabelHeight.constant = msgLabel.retrieveTextHeight()
    configureTimerLabel(item)
  }

  private func configureSubTagLabel(_ text: String) {
    subTagLabel.text = text
    let tagViewContentWith = 14 + tagLabel.intrinsicContentSize.width + 8
    let subTagLabelContentWith = subTagLabel.intrinsicContentSize.width
    let subTagLabelMaxWidth = UIScreen.main.bounds.size.width - 30 - 80 - tagViewContentWith - 16 - 30
    if subTagLabelContentWith > subTagLabelMaxWidth {
      subTagLabel.text = nil
      subTagLabelHeight.constant = 0.0
      backupLabel.text = text
      backupLabelHeight.constant = 16.0
    }
  }

  private func configureTimerLabel(_ item: PromotionVmItem) {
    if let bonusCoupon = item as? BonusCouponItem {
      configureBonusCouponItem(bonusCoupon)
    }
    else if let promotion = item as? PromotionEventItem {
      configurePromotionEventItem(promotion)
    }
  }

  private func configureBonusCouponItem(_ bonusCoupon: BonusCouponItem) {
    let now = Date()
    if let duration = bonusCoupon.validPeriod as? ValidPeriod.Duration {
      configureValidPeriodLayout(duration)
      setTextPerSecond(now, duration)
      let remainTime = TimeInterval(duration.countLeftMilliSeconds()) / 1000
      if self.timer == nil {
        self.timer = CountDownTimer()
      }
      self.timer?.start(timeInterval: 1, duration: remainTime) { [weak self] _, _, finish in
        if finish {
          self?.refreshCallback?()
        }
        else {
          self?.setTextPerSecond(Date(), duration)
        }
      }
    }
    else if let always = bonusCoupon.validPeriod as? ValidPeriod.Always {
      configureValidPeriodLayout(now, always)
    }
  }

  private func configurePromotionEventItem(_ promotion: PromotionEventItem) {
    let now = Date()
    let endDate = promotion.expireDate
    configurePromotionEventLayout()
    configureEndDate(now: now, endDate: endDate)
    let remainTime = endDate - now
    if self.timer == nil {
      self.timer = CountDownTimer()
    }
    self.timer?.start(timeInterval: 1, duration: remainTime) { [weak self] _, _, finish in
      if finish {
        self?.refreshCallback?()
      }
      else {
        self?.configureEndDate(now: Date(), endDate: endDate)
      }
    }
  }

  public func configureValidPeriodLayout(_: ValidPeriod.Duration) {
    fatalError("implements in subclass")
  }

  public func configureValidPeriodLayout(_: Date, _: ValidPeriod.Always) {
    fatalError("implements in subclass")
  }

  public func configurePromotionEventLayout() {
    fatalError("implements in subclass")
  }

  private func setTextPerSecond(_ now: Date, _ period: ValidPeriod.Duration) {
    let localizedStr = generalPeriodString(now: now, period: period)
    timerLabel.text = localizedStr
  }

  private func generalPeriodString(now: Date, period: ValidPeriod.Duration) -> String {
    var dayComponent = DateComponents()
    dayComponent.hour = -48
    let theCalendar = Calendar.current
    let periodStartDate = period.start.convertToDate()
    let periodEndDate = period.end.convertToDate()

    guard
      let periodStartMinus48 = theCalendar.date(byAdding: dayComponent, to: periodStartDate),
      let periodEndMinus48 = theCalendar.date(byAdding: dayComponent, to: periodEndDate)
    else {
      return Localize.string("bonus_status_expirydate", "00:00:00")
    }

    if now < periodStartMinus48 {
      return Localize.string("bonus_couponnostart", periodStartDate.toDateString())
    }
    else if now > periodStartMinus48, now < periodStartDate {
      let diff = (periodStartDate - now).timeRemainingFormatted()
      return Localize.string("bonus_couponnostart", diff)
    }
    else if now > periodStartDate, now < periodEndMinus48 {
      return Localize.string("bonus_status_expirydate", periodEndDate.toDateString())
    }
    else if now > periodStartDate, now > periodEndMinus48 {
      let diff = abs(now - periodEndDate).timeRemainingFormatted()
      return Localize.string("bonus_status_expirydate", diff)
    }
    return Localize.string("bonus_status_expirydate", "00:00:00")
  }

  private func configureEndDate(now: Date, endDate: Date) {
    let localizedString = getPromotionPeriod(now: now, endDate: endDate)
    timerLabel.text = localizedString
  }

  private func getPromotionPeriod(now: Date, endDate: Date) -> String {
    var dayComponent = DateComponents()
    dayComponent.hour = -48
    let theCalendar = Calendar.current
    guard let periodEndMinus48 = theCalendar.date(byAdding: dayComponent, to: endDate) else {
      return ""
    }
    if now < periodEndMinus48 {
      return Localize.string("bonus_status_expirydate", endDate.toDateString())
    }
    else if now > periodEndMinus48 {
      let diff = (endDate - now).timeRemainingFormatted()
      return Localize.string("bonus_status_expirydate", diff)
    }
    return ""
  }
}
