import UIKit
import SharedBu

typealias DisplayProductViewModel = ProductFavoriteViewModelProtocol & ProductWebGameViewModelProtocol
typealias DisplayProduct = DisplayBaseViewController & ProductBaseCollection

protocol ProductBaseCollection: AnyObject {
    func setCollectionView() -> UICollectionView
    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate
    func setViewModel() -> DisplayProductViewModel?
}

class DisplayBaseViewController: AppVersionCheckViewController, ProductVCProtocol {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    func setup() {
        guard let `self` = self as? DisplayProduct else { return }
        let collectionView = self.setCollectionView()
        collectionView.registerCellFromNib(WebGameItemCell.className)
        collectionView.delegate = self.setProductGameDataSourceDelegate()
        collectionView.dataSource = self.setProductGameDataSourceDelegate()
    }
    
    func reloadGameData(_ games: [WebGameWithDuplicatable]) {
        guard let `self` = self as? DisplayProduct else { return }
        self.setProductGameDataSourceDelegate().setGames(games)
        self.setCollectionView().reloadData()
    }
    
    func toggleFavorite(_ game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction) -> (), onError: @escaping (Error) -> ()) {
        guard let `self` = self as? DisplayProduct else { return }
        self.setViewModel()?.toggleFavorite(game: game, onCompleted: onCompleted, onError: onError)
    }
    
    func getProductViewModel() -> ProductWebGameViewModelProtocol? {
        guard let `self` = self as? DisplayProduct else { return nil }
        return self.setViewModel()
    }
    
    public func addBtnTags(stackView: UIStackView, data: [BaseGameTag]) {
        stackView.removeAllArrangedSubviews()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        
        var btns: [[UIButton]] = [[]]
        var childRow = createOneChildView(stackView)
        var rowInex = 0
        stackView.addArrangedSubview(childRow)
        for i in 0..<data.count {
            let dx = btns[rowInex].reduce(0) { (total, btn) -> CGFloat in
                return total + btn.frame.size.width + 8
            }
            let frame = CGRect(x: dx, y: 0, width: 180, height: 40 )
            let button = UIButton(frame: frame)
            button.setTitle("\(data[i].name)", for: .normal)
            button.titleLabel?.font =  UIFont(name: "PingFangSC-Medium", size: 12)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
            button.sizeToFit()
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
            if data[i].isSelected {
                button.applyGradient(vertical: [UIColor(rgb: 0xf74d25).cgColor, UIColor(rgb: 0xf20000).cgColor])
                button.setTitleColor(UIColor.whiteFull, for: .normal)
            } else {
                button.applyGradient(vertical: [UIColor(rgb: 0x32383e).cgColor, UIColor(rgb: 0x17191c).cgColor])
                button.setTitleColor(UIColor.textPrimaryDustyGray, for: .normal)
            }
            if dx+button.frame.size.width > stackView.frame.size.width {
                childRow = createOneChildView(stackView)
                rowInex += 1
                btns.append([])
                stackView.addArrangedSubview(childRow)
                button.frame.origin.x = 0
            }
            button.tag = Int(data[i].tagId)
            button.isSelected = data[i].isSelected
            button.addTarget(self, action: #selector(pressGameTag(_:)), for: .touchUpInside)
            childRow.addSubview(button)
            btns[rowInex].append(button)
        }
    }
    
    private func createOneChildView(_ parentView: UIStackView) -> UIView {
        let childRow = UIView(frame: .zero)
        childRow.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        childRow.widthAnchor.constraint(equalToConstant: parentView.frame.size.width).isActive = true
        return childRow
    }
    
    @objc public func pressGameTag(_ sender: UIButton) {
        
    }

}

protocol BaseGameTag: AnyObject {
    var tagId: Int32 { get }
    var isSelected: Bool { get set }
    var name: String { get }
}
