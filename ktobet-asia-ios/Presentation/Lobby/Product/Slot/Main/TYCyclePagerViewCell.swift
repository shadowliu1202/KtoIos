import RxSwift
import UIKit

class TYCyclePagerViewCell: UICollectionViewCell {
    lazy var label = UILabel()
    lazy var imageView = UIImageView()
    lazy var button = UIButton()
    lazy var backgroundImage = UIImageView()

    var toggleFavorite: (() -> Void)?
    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addImage()
        self.addBackgroundImage()
        self.addTextLabel()
        self.addFavoriteButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addImage()
        self.addBackgroundImage()
        self.addTextLabel()
        self.addFavoriteButton()
    }

    func addTextLabel() {
        self.addSubview(self.label)
        self.label.textColor = UIColor.white
        self.label.textAlignment = NSTextAlignment.left
        self.label.font = UIFont(name: "PingFangSC-Medium", size: 14)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 9).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -17).isActive = true
    }

    func addImage() {
        self.addSubview(self.imageView)
        self.imageView.cornerRadius = 16
        self.imageView.clipsToBounds = true
    }

    func addFavoriteButton() {
        self.addSubview(button)
        self.button.setImage(UIImage(named: "game-favorite-activeinactive"), for: .normal)
        self.button.sizeToFit()
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        self.button.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -17).isActive = true
        self.button.rx.tap.subscribe(onNext: { [weak self] in
            self?.toggleFavorite?()
        }).disposed(by: disposeBag)
    }

    func addBackgroundImage() {
        self.addSubview(backgroundImage)
        backgroundImage.image = UIImage(named: "game-icon-big")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.backgroundImage.frame = self.bounds
    }
}
