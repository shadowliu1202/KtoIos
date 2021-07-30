import UIKit
import SharedBu
import RxSwift


class LevelPrivilegeDetailViewController: UIViewController {
    static let segueIdentifier = "toPrivilegeDetail"
    
    @IBOutlet private weak var btnPromotion: UIButton!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var levelLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var constraintTableViewHeight : NSLayoutConstraint!
    @IBOutlet private weak var backgroundViewHeight : NSLayoutConstraint!
    @IBOutlet private weak var dailyLimitAmountLabel: UILabel!
    @IBOutlet private weak var buttonBackgroundView: UIView!
    @IBOutlet private weak var productUnlimitedView: UIView!
    @IBOutlet private weak var productUnlimitedTopBarView: UIView!
    
    var levelPrivilege: LevelPrivilege!
    var level: Int32!
    private var arg: PrivilegeArg!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self, image: "iconNavBack24")
        
        btnPromotion.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        backgroundView.setViewCorner(topCorner: true, bottomCorner: false, radius: 32)
        levelLabel.layer.masksToBounds = true
        levelLabel.layer.cornerRadius = 16
        levelLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonBackgroundView.addBorder(.top, size: 1, color: UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 0.3))
        
        levelLabel.text = String(format: Localize.string("common_level_2"), String(level))
        switch levelPrivilege {
        case is LevelPrivilege.Deposit:
            arg = generateDepositView()
        case is LevelPrivilege.Rebate:
            arg = generateProductFeedback()
        case is LevelPrivilege.ProductSlotRescue:
            arg = generateSlot()
        case is LevelPrivilege.ProductBetInsurance:
            arg = generateInsureance()
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make the navigation bar background clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore the navigation bar to default
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    private func generateDepositView() -> PrivilegeArg {
        titleLabel.text = Localize.string("common_depositbonus")
        iconImageView.image = UIImage(named: "lvDetailBank")
        var cells: [UITableViewCell] = []
        if let data = levelPrivilege as? LevelPrivilege.Deposit {
            for row in 0..<(level >= 3 ? 4 : 3) {
                let detailCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailTableViewCell") as! LevelDetailTableViewCell
                let detail2Cell = tableView.dequeueReusableCell(withIdentifier: "LevelDetail2TableViewCell") as! LevelDetail2TableViewCell
                
                if row == 1 {
                    detailCell.leftLabel.text = Localize.string("level_detail_5_title1")
                    detailCell.rightLabel.text = data.maxBonus.amount.currencyFormatWithoutSymbol(precision: 0)
                    cells.append(detailCell)
                } else if row == 0 {
                    detailCell.leftLabel.text = Localize.string("level_detail_5_title1_first")
                    detailCell.rightLabel.text = data.percentage.currencyFormatWithoutSymbol(precision: 0) + "%"
                    cells.append(detailCell)
                } else if row == 2 {
                    if level <= 2 {
                        detail2Cell.titleLabel.text = Localize.string("level_detail_5_title3")
                        detail2Cell.secondLabel.text = String(format: Localize.string("level_detail_5_content3"), String(data.minCapital), String(data.betMultiple))
                    } else {
                        switch data.issueFrequency {
                        case .daily:
                            detail2Cell.titleLabel.text = Localize.string("level_detail_5_title2_3")
                            detail2Cell.secondLabel.text = Localize.string("level_detail_5_content2_3")
                        case .weekly:
                            detail2Cell.titleLabel.text = Localize.string("level_detail_5_title2_2")
                            detail2Cell.secondLabel.text = Localize.string("level_detail_5_content2_2")
                        case .monthly:
                            detail2Cell.titleLabel.text = Localize.string("level_detail_5_title2_1")
                            detail2Cell.secondLabel.text = Localize.string("level_detail_5_content2_1")
                        default:
                            break
                        }
                    }
                    
                    cells.append(detail2Cell)
                } else if row == 3 {
                    if level >= 3 {
                        detail2Cell.titleLabel.text = Localize.string("level_detail_5_title2_1")
                        detail2Cell.secondLabel.text = String(format: Localize.string("level_detail_5_content3"), String(data.minCapital.currencyFormatWithoutSymbol(precision: 0)), String(data.betMultiple))
                    }
                    
                    cells.append(detail2Cell)
                }
            }
        }
        
        cells.append(UITableViewCell())
        return PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateProductFeedback() -> PrivilegeArg {
        titleLabel.text = Localize.string("level_product_rebate")
        iconImageView.image = UIImage(named: "lvDetailProduct")
        footerView.isHidden = false
        var cells: [UITableViewCell] = []
        if let data = levelPrivilege as? LevelPrivilege.Rebate {
            dailyLimitAmountLabel.text = data.maxBonus.amount.currencyFormatWithoutSymbol(precision: 0)
            let titles = [Localize.string("common_sportsbook"), Localize.string("common_casino"), Localize.string("common_slot"), Localize.string("common_keno")]
            let sbkPercentage = Double(truncating: data.percentages[ProductType.sbk] ?? 0)
            let casinoPercentage = Double(truncating: data.percentages[ProductType.casino] ?? 0)
            let slotPercentage = Double(truncating: data.percentages[ProductType.slot] ?? 0)
            let numberGamePercentage = Double(truncating: data.percentages[ProductType.numbergame] ?? 0)
            let content = [sbkPercentage.currencyFormatWithoutSymbol(precision: 0) + "%",
                           casinoPercentage.currencyFormatWithoutSymbol(precision: 0) + "%",
                           slotPercentage.currencyFormatWithoutSymbol(precision: 0) + "%",
                           numberGamePercentage.currencyFormatWithoutSymbol(precision: 0) + "%"]
            for i in 0...3 {
                let detailCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailTableViewCell") as! LevelDetailTableViewCell
                detailCell.leftLabel.text = titles[i]
                detailCell.rightLabel.text = content[i]
                cells.append(detailCell)
            }
            
            cells.append(UITableViewCell())
            
            if !data.isMaxBonusLimited() {
                productUnlimitedTopBarView.backgroundColor = UIColor.orangeFull
                productUnlimitedView.backgroundColor = UIColor(red: 1, green: 128/255, blue: 0, alpha: 0.2)
                dailyLimitAmountLabel.text = Localize.string("bonus_unlimited")
            }
        }
        
        return PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateSlot() -> PrivilegeArg {
        titleLabel.text = Localize.string("bonus_bonusproducttype_2")
        iconImageView.image = UIImage(named: "lvDetailSlot")
        var cells: [UITableViewCell] = []
        let detail2Cell = tableView.dequeueReusableCell(withIdentifier: "LevelDetail2TableViewCell") as! LevelDetail2TableViewCell
        let imageCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailImageTableViewCell") as! LevelDetailImageTableViewCell
        
        detail2Cell.titleLabel.text = Localize.string("level_detail_3_1_title")
        detail2Cell.secondLabel.text = Localize.string("level_detail_3_1_content")
        cells.append(detail2Cell)
        if level >= 1 && level <= 4 {
        imageCell.slotImageView.image = UIImage(named: "group1-4")
        } else if level >= 5 && level <= 6 {
            imageCell.slotImageView.image = UIImage(named: "group5-6")
        } else if level >= 7 && level <= 8 {
            imageCell.slotImageView.image = UIImage(named: "group7-8")
        } else {
            imageCell.slotImageView.image = UIImage(named: "group9+")
        }
        
        cells.append(imageCell)
        
        return PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateInsureance() -> PrivilegeArg {
        titleLabel.text = Localize.string("level_producttype_1")
        iconImageView.image = UIImage(named: "lvDetailInsure")
        var cells: [UITableViewCell] = []
        if let data = levelPrivilege as? LevelPrivilege.ProductBetInsurance {
            let titles = [Localize.string("level_detail_3_1_title1"), Localize.string("level_detail_3_1_title2")]
            let contents = [data.percentage.currencyFormatWithoutSymbol(precision: 0),
                            data.maxBonus.amount.currencyFormatWithoutSymbol(precision: 0)]
            for i in 0..<2 {
                let detailCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailTableViewCell") as! LevelDetailTableViewCell
                detailCell.leftLabel.text = titles[i]
                detailCell.rightLabel.text = contents[i]
                cells.append(detailCell)
            }
        }
        
        cells.append(UITableViewCell())
        return PrivilegeArg(cells: cells, rowCount: cells.count)
    }
}

struct PrivilegeArg {
    var cells: [UITableViewCell]
    var rowCount: Int
}

extension LevelPrivilegeDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arg.rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return arg.cells[indexPath.row]
    }
}
