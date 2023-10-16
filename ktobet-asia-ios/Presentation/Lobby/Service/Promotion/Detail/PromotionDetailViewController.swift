import RxCocoa
import RxSwift
import sharedbu
import UIKit
import WebKit

class PromotionDetailViewController: LobbyViewController {
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
  @IBOutlet weak var cashBackInfoStackView: UIStackView!

  private let stampIconImageView = UIImageView()

  private let yellowGradient = [
    UIColor.complementaryDefault.cgColor,
    UIColor(red: 254 / 255, green: 161 / 255, blue: 68 / 255, alpha: 1).cgColor
  ]
  private let yellowGradientAlpha60 = [
    UIColor.complementaryDefault.withAlphaComponent(0.6).cgColor,
    UIColor(red: 254 / 255, green: 161 / 255, blue: 68 / 255, alpha: 0.6).cgColor
  ]
  private let yellowGradientAlpha20 = [
    UIColor.complementaryDefault.withAlphaComponent(0.2).cgColor,
    UIColor(red: 254 / 255, green: 161 / 255, blue: 68 / 255, alpha: 0.2).cgColor
  ]

  private var localStorageRepo = Injectable.resolveWrapper(LocalStorageRepository.self)

  fileprivate var disposeBag = DisposeBag()

  var viewModel: PromotionViewModel!
  var item: PromotionVmItem!

  var subUseBonusCoupon = SubUseBonusCoupon()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    getPromotionButton.applyGradient(horizontal: yellowGradient)
    topBackgroundView.applyGradient(horizontal: yellowGradient)

    textViewContent.linkTextAttributes = [
      .underlineStyle: NSUnderlineStyle.single.rawValue,
      .underlineColor: UIColor.primaryDefault,
      .foregroundColor: UIColor.primaryDefault
    ]
    textViewRule.linkTextAttributes = [
      .underlineStyle: NSUnderlineStyle.single.rawValue,
      .underlineColor: UIColor.primaryDefault,
      .foregroundColor: UIColor.primaryDefault
    ]

    textViewContent.delegate = self
    textViewRule.delegate = self

    stampIconImageView.contentMode = .scaleToFill

    topBackgroundView.addSubview(stampIconImageView)
    stampIconImageView.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 40, height: 32))
      make.top.equalTo(30)
      make.trailing.equalTo(0)
    }

    let promotionDetail = Driver.combineLatest(
      viewModel.getPromotionDetail(id: item.id),
      viewModel.playerLevel.asDriver(onErrorJustReturn: ""))
    promotionDetail.map { self.replaceContent(text: $0.content, level: $1) }.drive(textViewContent.rx.attributedText)
      .disposed(by: disposeBag)
    promotionDetail.map { self.replaceContent(text: $0.rules, level: $1) }.drive(textViewRule.rx.attributedText)
      .disposed(by: disposeBag)

    setView(
      productTypeTitle: item.title,
      productSubType: item.subTitle,
      productName: item.message,
      issueNumber: item.issueNo,
      productTypeDrawable: item.icon,
      promotionAmount: item.displayAmount,
      validPeriod: (item as? BonusCouponItem)?.validPeriod,
      isFull: (item as? PromotionEventItem)?.isAutoUse() ?? false,
      stampIconName: item is BonusCoupon.VVIPCashback || item is PromotionEvent
        .VVIPCashback ? "VVIPCashBackDetailPageIcon" : nil,
      promotionId: item is BonusCoupon.VVIPCashback || item is PromotionEvent.VVIPCashback ? item.id : nil)

    getPromotionButton.rx.tap.subscribe(onNext: { [unowned self] in
      if let bonusCoupon = self.item as? BonusCoupon {
        self.viewModel.requestCouponApplication(bonusCoupon: bonusCoupon)
          .flatMapCompletable({ [weak self] waiting in
            guard let self else { return .empty() }

            return self.subUseBonusCoupon.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
          }).subscribe(onCompleted: { [weak self] in
            self?.viewModel.fetchData()
          }, onError: { [weak self] error in
            self?.handleErrors(error)
          }).disposed(by: self.disposeBag)
      }
    })
    .disposed(by: disposeBag)
  }

  private func replaceContent(text: String, level: String) -> NSMutableAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = 1.2
    let fontAttribute = [
      NSAttributedString.Key.font: UIFont(name: "PingFangSC-Regular", size: 14)!,
      NSAttributedString.Key.foregroundColor: UIColor.textSecondary,
      NSAttributedString.Key.paragraphStyle: paragraphStyle
    ]

    var attributedString = NSMutableAttributedString(string: text, attributes: fontAttribute)
    replaceParameter(text: &attributedString, parameter: "{date}", value: self.item.displayInformPlayerDate)
    replaceParameter(text: &attributedString, parameter: "{maxbonus}", value: self.item.displayMaxAmount)
    replaceParameter(
      text: &attributedString,
      parameter: "{multiple}",
      value: (self.item as? BonusCouponItem)?.displayBetMultiple ?? "")
    replaceParameter(text: &attributedString, parameter: "{level}", value: self.item.displayLevel ?? level)
    replaceParameter(text: &attributedString, parameter: "{percentage}", value: self.item.displayPercentage)
    replaceParameter(
      text: &attributedString,
      parameter: "{mincapital}",
      value: (self.item as? BonusCouponItem)?.displayMinCapital ?? "")
    replaceBonusTnc(text: &attributedString, parameter: "{bonustnc}", value: Localize.string("bonus_detail_contentrule"))
    replaceBonusTnc(text: &attributedString, parameter: "{month}", value: item.issueNo)
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
    text.addAttribute(.foregroundColor, value: UIColor.primaryDefault, range: NSRange(location: index, length: value.count))
    text.addAttribute(
      .font,
      value: UIFont(name: "PingFangSC-Regular", size: 14)!,
      range: NSRange(location: index, length: value.count))
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func setView(
    productTypeTitle: String,
    productSubType: String,
    productName: String,
    issueNumber: String?,
    productTypeDrawable: String,
    promotionAmount: String,
    validPeriod _: ValidPeriod?,
    isFull: Bool = false,
    stampIconName: String?,
    promotionId: String?)
  {
    typeButton.setTitle(productTypeTitle, for: .normal)
    subTypeLabel.isHidden = productSubType.isEmpty
    subTypeLabel.text = productSubType
    issueNumberLabel.isHidden = issueNumber?.isEmpty ?? true
    issueNumberLabel.text = issueNumber
    nameLabel.text = productName
    amountLabel.text = promotionAmount.replacingOccurrences(of: "\n", with: " ")
    promotionImageView.image = UIImage(named: productTypeDrawable)
    setStatusImageView(isFull)

    if let stampIconName {
      stampIconImageView.image = UIImage(named: stampIconName)
    }
    else {
      stampIconImageView.visibility = .gone
    }

    switch item {
    case let bonusItem as BonusCouponItem:
      configureBonusCouponItem(bonusItem)
      let verify = bonusItem.validPeriod.verify(time: Date().toUTCOffsetDateTime())
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

    setupCashBackInfoStackView(id: promotionId)
  }

  private func setStatusImageView(_ isAutoUse: Bool) {
    if isAutoUse {
      statusImageView.image = Theme.shared.getUIImage(name: "promotionAutoUse", by: localStorageRepo.getSupportLocale())
      statusImageView.isHidden = false
    }
    else {
      statusImageView.isHidden = true
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
    CountDownTimer().start(timeInterval: 1, endTime: endDate) { [weak self] _, _, _ in
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
    }
    else {
      expireDateLabel.text = Localize.string("bonus_status_expirydate", endDate.toDateString())
    }
  }

  private func startExpireDateDisplayCounter(_ period: ValidPeriod.Duration) {
    let remainTime = TimeInterval(period.countLeftMilliSeconds()) / 1000
    CountDownTimer().start(timeInterval: 1, duration: remainTime) { [weak self] _, _, finish in
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

    guard
      let periodStartMinus48 = calendar.date(byAdding: dayComponent, to: periodStartDate),
      let periodEndMinus48 = calendar.date(byAdding: dayComponent, to: periodEndDate)
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

  private func setupCashBackInfoStackView(id promotionId: String?) {
    guard let id = promotionId
    else {
      cashBackInfoStackView.visibility = .gone
      return
    }

    cashBackInfoStackView.addArrangedSubview(
      ListRow(rowConfig: .init(
        field1: Localize.string("bonus_cashback_loss_amount"),
        field2: Localize.string("bonus_cashback_percent"),
        field3: Localize.string("bonus_cashback_max_amount"),
        textColor: .black,
        rowBackgroundColor: .init(gradientColor: yellowGradientAlpha60))))

    viewModel.getCashBackSettings(id: id)
      .subscribe(onSuccess: { [weak self] settings in
        settings.enumerated().forEach { index, setting in
          self?.cashBackInfoStackView.addArrangedSubview(
            ListRow(rowConfig: .init(
              field1: setting.lossAmountRange,
              field2: setting.cashBackPercentage.description() + "%",
              field3: setting.maxAmount.description(),
              textColor: .yellowEA9E16,
              rowBackgroundColor: index % 2 == 0 ? .init(backgroundColor: .white) :
                .init(gradientColor: self?.yellowGradientAlpha20))))
        }
      })
      .disposed(by: disposeBag)

    cashBackInfoStackView.visibility = .visible
  }
}

extension PromotionDetailViewController: UITextViewDelegate {
  func textView(_: UITextView, shouldInteractWith _: URL, in _: NSRange, interaction _: UITextItemInteraction) -> Bool {
    performSegue(withIdentifier: PromotionRuleTermViewController.segueIdentifier, sender: nil)
    return false
  }
}

// MARK: - ListRow

extension PromotionDetailViewController {
  class ListRow: UIView {
    struct RowConfig {
      let field1: String
      let field2: String
      let field3: String
      let textColor: UIColor
      let rowBackgroundColor: ColorSet
    }

    struct ColorSet {
      var backgroundColor: UIColor?
      var gradientColor: [CGColor]?
    }

    let field1Label = UILabel()
    let field2Label = UILabel()
    let field3Label = UILabel()

    lazy var labels = [field1Label, field2Label, field3Label]

    init(rowConfig: RowConfig) {
      super.init(frame: .zero)
      setupUI()
      config(rowConfig)
    }

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
      setupUI()
    }

    private func setupUI() {
      let hstack = UIStackView(
        arrangedSubviews: labels,
        spacing: 0,
        axis: .horizontal,
        distribution: .fill,
        alignment: .fill)

      for label in labels {
        label.font = UIFont(name: "PingFangSC-Medium", size: 12)!
        label.textAlignment = .center
        label.numberOfLines = 0
      }

      addSubview(hstack)
      hstack.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0))
      }

      field1Label.snp.makeConstraints { make in
        make.width.equalToSuperview().multipliedBy(0.5)
      }

      field2Label.snp.makeConstraints { make in
        make.width.equalToSuperview().multipliedBy(0.25)
      }

      field3Label.snp.makeConstraints { make in
        make.width.equalToSuperview().multipliedBy(0.25)
      }
    }

    func config(_ rowConfig: RowConfig) {
      field1Label.text = rowConfig.field1
      field2Label.text = rowConfig.field2
      field3Label.text = rowConfig.field3
      labels.forEach({ $0.textColor = rowConfig.textColor })

      if let color = rowConfig.rowBackgroundColor.backgroundColor {
        self.backgroundColor = color
      }
      else if let gradientColor = rowConfig.rowBackgroundColor.gradientColor {
        self.applyGradient(horizontal: gradientColor)
      }
    }
  }
}

extension UIColor {
  fileprivate static let yellowEA9E16: UIColor = #colorLiteral(red: 0.9176470588, green: 0.6196078431, blue: 0.0862745098, alpha: 1)
}
