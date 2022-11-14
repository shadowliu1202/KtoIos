import UIKit
import RxSwift
import SharedBu

class UsableTableViewCell: PromotionTableViewCell {

    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        watermarkIcon.image = nil
    }
    
    func configure(_ item: PromotionVmItem) -> Self {
        setStampGradient()
        setStampIcon(item)
        super.setData(item)
        return self
    }
    
    func setClickGetCouponHandler(_ callback: (Observable<Void>, DisposeBag) -> Void) -> Self {
        callback(self.btnGetCoupon.rx.touchUpInside.asObservable(), disposeBag)
        return self
    }
    
    func configure(_ item: PromotionVmItem, _ autoUse: Bool = false, _ playerLocale: SupportLocale) -> Self {
        configureWatermark(autoUse, playerLocale)
        return self.configure(item)
    }
    
    private func setStampGradient() {
        self.stamp.applyGradient(vertical: [UIColor(rgb: 0xffd500).cgColor, UIColor(rgb: 0xfea144).cgColor])
    }
    
    private func setStampIcon(_ item: PromotionVmItem) {
        self.stampIcon.image = UIImage(named: item.stampIcon)
    }
    
    override func configureValidPeriodLayout(_ period: ValidPeriod.Duration) {
        let isValid  = period.verify(time: Date().toUTCOffsetDateTime())
        if isValid {
            setManualImmediately()
        } else {
            setGetInFuture()
        }
    }
    
    private func setManualImmediately() {
        setBtnGetCouponGradient()
        btnGetCoupon.isHidden = false
        btnGetCouponHeight.constant = BtnGetCouponHeight
        btnGetCoupon.setTitle(Localize.string("bonus_getcoupon"), for: .normal)
        timerLabel.textAlignment = .center
    }
    
    private func setGetInFuture() {
        btnGetCouponHeight.constant = 0
        btnGetCoupon.setTitle(nil, for: .normal)
        timerLabel.textAlignment = .left
    }
    
    private func setBtnGetCouponGradient() {
        self.btnGetCoupon.applyGradient(horizontal: [UIColor(rgb: 0xffd500).cgColor, UIColor(rgb: 0xfea144).cgColor])
    }
    
    override func configureValidPeriodLayout(_ now: Date, _ period: ValidPeriod.Always) {
        setBtnGetCouponGradient()
        btnGetCoupon.isHidden = false
        btnGetCouponHeight.constant = BtnGetCouponHeight
        btnGetCoupon.setTitle(Localize.string("bonus_getcoupon"), for: .normal)
        timerLabelHeight.constant = 0.0
    }
    
    override func configurePromotionEventLayout() {
        btnGetCouponHeight.constant = 0
        btnGetCoupon.setTitle(nil, for: .normal)
        timerLabel.textAlignment = .center
    }
    
    private func configureWatermark(_ autoUse: Bool, _ playerLocale: SupportLocale ) {
        if autoUse {
            watermarkIcon.image = Theme.shared.getUIImage(name: "promotionAutoUse", by: playerLocale)
        } else {
            watermarkIcon.image = nil
        }
    }
}
