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
        super.setData(item)
        return self
    }
    
    func setClickGetCouponHandler(_ callback: (Observable<Void>, DisposeBag) -> Void) -> Self {
        callback(self.btnGetCoupon.rx.touchUpInside.asObservable(), disposeBag)
        return self
    }
    
    func configure(_ item: PromotionVmItem, _ autoUse: Bool = false) -> Self {
        configureWatermark(autoUse)
        return self.configure(item)
    }
    
    private func setStampGradient() {
        self.stamp.applyGradient(vertical: [UIColor(rgb: 0xffd500).cgColor, UIColor(rgb: 0xfea144).cgColor])
    }
    
    override func configureValidPeriodLayout(_ now: Date, _ period: ValidPeriod.Duration) {
        let isValid  = period.verify(time: now.convertDateToOffsetDateTime())
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
    
    private func configureWatermark(_ autoUse: Bool) {
        if autoUse {
            watermarkIcon.image = UIImage(named: "promotionAutoUse")
        } else {
            watermarkIcon.image = nil
        }
    }
}
