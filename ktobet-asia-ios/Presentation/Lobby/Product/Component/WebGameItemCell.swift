import RxSwift
import SDWebImage
import SharedBu
import UIKit

class WebGameItemCell: UICollectionViewCell {
  private var httpClient = Injectable.resolve(HttpClient.self)!
  @IBOutlet weak var labelHeight: NSLayoutConstraint!
  @IBOutlet weak var mainView: UIView!
  @IBOutlet weak var gameImage: UIImageView!
  @IBOutlet weak var backgroundImage: UIImageView!
  @IBOutlet weak var favoriteBtn: UIButton!
  @IBOutlet weak var labTitle: UILabel!
  @IBOutlet private weak var blurView: UIView!
  @IBOutlet private weak var blurLabel: UILabel!
  @IBOutlet private weak var blurImageView: UIImageView!
  
  private var toggleFavoriteProcessing = false
  
  var isFavorite = false
  var favoriteBtnClick: (() -> Void)?
  lazy var disposeBag = DisposeBag()

  override func awakeFromNib() {
    super.awakeFromNib()
    mainView.translatesAutoresizingMaskIntoConstraints = false
    let width = floor((UIScreen.main.bounds.size.width - 24 * 2 - 14 * 2) / 3)
    self.mainView.constrain([.equal(\.widthAnchor, length: width)])
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
    gameImage.sd_cancelCurrentImageLoad()
    gameImage.image = nil
    isUserInteractionEnabled = true
  }

  @discardableResult
  func configure(game: WebGameWithProperties) -> Self {
    gameImage.sd_setImage(url: URL(string: game.thumbnail.url()), placeholderImage: nil)
    backgroundImage.image = UIImage(named: "game-icon-small")
    isFavorite = game.isFavorite
    let imgName = game.isFavorite == true ? "game-favorite-active" : "game-favorite-activeinactive"
    favoriteBtn.setImage(UIImage(named: imgName), for: .normal)
    labTitle.text = game.gameName
    switch game.gameState() {
    case .active:
      blurView.isHidden = true
    case .inactive(let text, let icon),
         .maintenance(let text, let icon):
      blurView.isHidden = false
      blurLabel.text = text
      blurImageView.image = icon
    }

    favoriteBtn.rx.touchUpInside
      .bind(onNext: { [unowned self] in
        guard !toggleFavoriteProcessing else { return }
        favoriteBtnClick?()
      })
      .disposed(by: disposeBag)
    
    return self
  }
  
  func setToggleFavoriteProcessing(_ inProcess: Bool) {
    toggleFavoriteProcessing = inProcess
  }
  
  func toggleFavoriteIcon() {
    isFavorite.toggle()
    let imgName = isFavorite ? "game-favorite-active" : "game-favorite-activeinactive"
    favoriteBtn.setImage(UIImage(named: imgName), for: .normal)
  }
}

class WebGameSearchItemCell: WebGameItemCell {
  private var previousKeyword: String?

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
    self.labTitle.highlight(text: previousKeyword, color: .clear)
  }

  func configure(game: WebGameWithProperties, searchKeyword: String?) -> Self {
    super.configure(game: game)
    self.previousKeyword = searchKeyword
    self.labTitle.highlight(
      text: searchKeyword?.trimmingCharacters(in: .whitespacesAndNewlines),
      color: .primaryDefault.withAlphaComponent(0.5))
    return self
  }
}
