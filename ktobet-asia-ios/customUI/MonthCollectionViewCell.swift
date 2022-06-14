import UIKit
import RxSwift
import RxCocoa
import SharedBu

class MonthCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var label: UILabel!
    @IBOutlet fileprivate weak var interactiveBtn: UIButton!
    @IBOutlet private weak var backView: UIView!
    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func config(_ month: Int, playerLocale: SupportLocale, isEnable: Bool, isSelected: Bool, callback: (Observable<Void>, DisposeBag) -> Void) {
        self.label.text = Theme.shared.getMonthCollectionViewCellTitle(month, by: playerLocale)
        self.label.textColor = isSelected ? UIColor.black_two : isEnable ? UIColor.whiteFull : UIColor.textSecondaryScorpionGray
        self.interactiveBtn.isEnabled = isEnable
        self.backView.backgroundColor = isSelected ? UIColor.yellowFull : UIColor.clear
        callback(self.interactiveBtn.rx.touchUpInside.asObservable(), disposeBag)
    }
}
