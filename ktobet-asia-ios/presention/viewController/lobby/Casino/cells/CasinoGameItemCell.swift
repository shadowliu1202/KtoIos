import UIKit
import RxSwift
import share_bu
import SDWebImage

class CasinoGameItemCell: UICollectionViewCell {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var favoriteBtn: UIButton!
    @IBOutlet weak var labTitle : UILabel!
    @IBOutlet private weak var blurView: UIView!
    @IBOutlet private weak var blurLabel: UILabel!
    @IBOutlet private weak var blurImageView: UIImageView!
    var favoriteBtnClick: (() -> ())?
    lazy var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        let width = floor( (UIScreen.main.bounds.size.width - 24 * 2 - 14 * 2) / 3 )
        self.mainView.constrain([.equal(\.widthAnchor, length: width)])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        gameImage.sd_cancelCurrentImageLoad()
        gameImage.image = nil
    }
    
    @discardableResult
    func configure(game: CasinoGame) -> Self {
        let imageDownloader = SDWebImageDownloader.shared
        for header in HttpClient().headers {
            imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
        }
        gameImage.sd_setImage(with: URL(string: game.thumbnail.url()), completed: nil)
        backgroundImage.image = UIImage(named: "game-icon-small")
        let imgName = game.isFavorite == true ? "game-favorite-active" : "game-favorite-activeinactive"
        favoriteBtn.setImage(UIImage(named: imgName), for: .normal)
        labTitle.text = game.gameName
        switch game.gameState {
        case .active:
            blurView.isHidden = true
        case .inactive(let text, let icon), .maintenance(let text, let icon):
            blurView.isHidden = false
            blurLabel.text = text
            blurImageView.image = icon
        }
        favoriteBtn.rx.touchUpInside.bind(onNext: { [weak self] in
            self?.favoriteBtnClick?()
        }).disposed(by: disposeBag)
        return self
    }
}

class CasinoGameSearchItemCell: CasinoGameItemCell {
    @IBOutlet weak var labelHeight: NSLayoutConstraint!
    private var previousKeyword: String?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        self.labTitle.highlight(text: previousKeyword, color: .clear)
    }
    
    func configure(game: CasinoGame, searchKeyword: String?) -> Self {
        super.configure(game: game)
        self.previousKeyword = searchKeyword
        self.labTitle.highlight(text: searchKeyword, color: .redForDark502)
        labelHeight.constant = labTitle.retrieveTextHeight()
        return self
    }
}
