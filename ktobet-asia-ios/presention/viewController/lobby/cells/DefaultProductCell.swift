import UIKit
import SharedBu

class DefaultProductCell: UITableViewCell {

    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var viewBg : UIView!
    @IBOutlet private weak var imgBackground : UIImageView!
    @IBOutlet private weak var viewShadow : UIView!
    
    @IBOutlet weak var titleLeading: NSLayoutConstraint!
    @IBOutlet weak var titleTrailing: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.viewBg.layer.masksToBounds = true
        self.viewBg.layer.cornerRadius = 8
        self.imgBackground?.layer.masksToBounds = true
        self.viewShadow.layer.masksToBounds = false
        self.viewShadow.layer.cornerRadius = 8
        self.viewShadow.layer.shadowColor = UIColor.white.cgColor
        self.viewShadow.layer.shadowPath = UIBezierPath(roundedRect: self.viewBg.bounds,
                                                        cornerRadius: self.viewBg.layer.cornerRadius).cgPath
        self.viewShadow.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.viewShadow.layer.shadowOpacity = 0.7
        self.viewShadow.layer.shadowRadius = 5
    }
    
    func setup(_ gameType: ProductType, _ local: SupportLocale, _ selectedGameType: ProductType?){
        let isSelected = gameType == selectedGameType ? true : false
        self.imgBackground?.image = isSelected ? try! getSelectImg(gameType) : try! getUnselectImg(gameType)
        self.labTitle.text = StringMapper.parseProductTypeString(productType: gameType)
        self.labDesc.text = try! getDesc(gameType)
        self.viewBg.layer.borderWidth = isSelected ? 1 : 0
        self.viewBg.layer.borderColor = (isSelected ? UIColor.white : UIColor.clear).cgColor
        self.viewShadow.isHidden = !isSelected
        titleLeading.constant = Theme.shared.getDefaultProductTextPadding(by: local)
        titleTrailing.constant = Theme.shared.getDefaultProductTextPadding(by: local)
    }
    
    private func getDesc(_ productType: ProductType) throws -> String {
        switch productType {
        case .sbk:
            return Localize.string("profile_defaultproduct_sportsbook_description")
        case .casino:
            return Localize.string("profile_defaultproduct_casino_description")
        case .slot:
            return Localize.string("profile_defaultproduct_slot_description")
        case .numbergame:
            return Localize.string("profile_defaultproduct_keno_description")
        default:
            throw KTOError.WrongProductType
        }
    }
    
    private func getSelectImg(_ productType: ProductType) throws -> UIImage {
        switch productType {
        case .sbk:
            return UIImage(named: "(375)SBK-Select")!
        case .casino:
            return UIImage(named: "(375)Casino-Select")!
        case .slot:
            return UIImage(named: "(375)Slot-Select")!
        case .numbergame:
            return UIImage(named: "(375)Number Game-Select")!
        default:
            throw KTOError.WrongProductType
        }
    }
    
    private func getUnselectImg(_ productType: ProductType) throws -> UIImage {
        switch productType {
        case .sbk:
            return UIImage(named: "(375)SBK-Unselect")!
        case .casino:
            return UIImage(named: "(375)Casino-Unselect")!
        case .slot:
            return UIImage(named: "(375)Slot-Unselect")!
        case .numbergame:
            return UIImage(named: "(375)Number Game-Unselect")!
        default:
            throw KTOError.WrongProductType
        }
    }
}
