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
    private var cells: [UITableViewCell] = []
    private var disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, image: "iconNavBack24")
        
        btnPromotion.applyGradient(horizontal: [UIColor.yellowFull.cgColor, UIColor(red: 254/255, green: 161/255, blue: 68/255, alpha: 1).cgColor])
        btnPromotion.rx.touchUpInside.subscribe(onNext:{
            NavigationManagement.sharedInstance.goTo(storyboard: "Promotion", viewControllerId: "PromotionNavigationController")
        }).disposed(by: disposeBag)
        backgroundView.setViewCorner(topCorner: true, bottomCorner: false, radius: 32)
        levelLabel.layer.masksToBounds = true
        levelLabel.layer.cornerRadius = 16
        levelLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonBackgroundView.addBorder(.top, size: 1, color: UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 0.3))
        
        levelLabel.text = String(format: Localize.string("common_level_2"), String(level))
        switch levelPrivilege {
        case let depositData as LevelPrivilege.Deposit:
            generateDepositView(data: depositData)
        case let rebateData as LevelPrivilege.Rebate:
            generateProductFeedback(data: rebateData)
        case is LevelPrivilege.ProductSlotRescue:
            generateSlot()
        case let insuranceData as LevelPrivilege.ProductBetInsurance:
            generateInsureance(data: insuranceData)
        default:
            break
        }
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.clear
            appearance.shadowImage = UIImage(color: UIColor.clear)
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore the navigation bar to default
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            let navigationBar = UINavigationBar()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.whiteFull]
            appearance.backgroundColor = UIColor.black_two
            navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            self.navigationController?.navigationBar.standardAppearance = appearance
        }
    }
    
    private func generateDepositView(data: LevelPrivilege.Deposit) {
        titleLabel.text = Localize.string("common_depositbonus")
        iconImageView.image = UIImage(named: "lvDetailBank")
        if (1...2).contains(level) {
            cells = generateDepositLevelOneTwo(data: data)
        } else if (3...10).contains(level) {
            cells = generateDepositGreaterThanLevelTwo(data: data)
        }
        
        cells.last?.addBorder(.bottom, size: 0.5, color: .dividerCapeCodGray2, rightConstant: 40, leftConstant: 40)
        arg = PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateProductFeedback(data: LevelPrivilege.Rebate) {
        titleLabel.text = Localize.string("level_product_rebate")
        iconImageView.image = UIImage(named: "lvDetailProduct")
        footerView.isHidden = false
        dailyLimitAmountLabel.text = data.maxBonus.description()
        let titles = [Localize.string("common_sportsbook"), Localize.string("common_casino"), Localize.string("common_slot"), Localize.string("common_keno"), Localize.string("common_arcade")]
        let content: [String] =
            [data.percentages[ProductType.sbk]?.description() ?? "" + "%",
             data.percentages[ProductType.casino]?.description() ?? "" + "%",
             data.percentages[ProductType.slot]?.description() ?? "" + "%",
             data.percentages[ProductType.numbergame]?.description() ?? "" + "%",
             data.percentages[ProductType.arcade]?.description() ?? "" + "%"]
        
        for i in 0...4 {
            cells.append(generateDetailOneRowCell(leftContent: titles[i], RightContent: content[i]))
        }
        
        if !data.isMaxBonusLimited() {
            productUnlimitedTopBarView.backgroundColor = UIColor.orangeFull
            productUnlimitedView.backgroundColor = UIColor(red: 1, green: 128/255, blue: 0, alpha: 0.2)
            dailyLimitAmountLabel.text = Localize.string("bonus_unlimited")
        }
        
        cells.last?.addBorder(.bottom, size: 0.5, color: .dividerCapeCodGray2, rightConstant: 40, leftConstant: 40)
        arg = PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateSlot() {
        titleLabel.text = Localize.string("bonus_bonusproducttype_2")
        iconImageView.image = UIImage(named: "lvDetailSlot")
        cells.append(generateDetailTwoRowCell(firstRow: Localize.string("level_detail_3_1_title"), secondRow: Localize.string("level_detail_3_1_content")))
        
        let imageCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailImageTableViewCell") as! LevelDetailImageTableViewCell
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
        arg = PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateInsureance(data: LevelPrivilege.ProductBetInsurance) {
        titleLabel.text = Localize.string("level_producttype_1")
        iconImageView.image = UIImage(named: "lvDetailInsure")
        let titles = [Localize.string("level_detail_3_1_title1"), Localize.string("level_detail_3_1_title2")]
        let contents = [data.percentage.description(),
                        data.maxBonus.description()]
        for i in 0..<2 {
            cells.append(generateDetailOneRowCell(leftContent: titles[i], RightContent: contents[i]))
        }
        
        cells.append(UITableViewCell())
        arg = PrivilegeArg(cells: cells, rowCount: cells.count)
    }
    
    private func generateDepositLevelOneTwo(data: LevelPrivilege.Deposit) -> [UITableViewCell] {
        cells.append(generateDetailOneRowCell(leftContent: level == 1 ? Localize.string("level_detail_5_title1_first") : Localize.string("level_detail_5_title1"), RightContent: data.percentage.description() + "%"))
        cells.append(generateDetailOneRowCell(leftContent: Localize.string("level_detail_5_maxamount"),
                                              RightContent: data.maxBonus.description()))
        cells.append(generateDetailTwoRowCell(firstRow: Localize.string("level_detail_5_title3"),
                                              secondRow: String(format: Localize.string("level_detail_5_content3"), data.minCapital.description(), String(data.betMultiple))))
        
        return cells
    }
    
    private func generateDepositGreaterThanLevelTwo(data: LevelPrivilege.Deposit) -> [UITableViewCell] {
        cells.append(generateDetailOneRowCell(leftContent: Localize.string("level_detail_5_title1"), RightContent: data.percentage.description() + "%"))
        cells.append(generateDetailOneRowCell(leftContent: Localize.string("level_detail_5_maxamount"), RightContent: data.maxBonus.description()))
        
        var frequencyTitle = ""
        var frequencyContent = ""
        switch data.issueFrequency {
        case .daily:
            frequencyTitle = Localize.string("level_detail_5_title2_3")
            frequencyContent = Localize.string("level_detail_5_content2_3")
        case .weekly:
            frequencyTitle = Localize.string("level_detail_5_title2_2")
            frequencyContent = Localize.string("level_detail_5_content2_2")
        case .monthly:
            frequencyTitle = Localize.string("level_detail_5_title2_1")
            frequencyContent = Localize.string("level_detail_5_content2_1")
        default:
            break
        }
        
        cells.append(generateDetailTwoRowCell(firstRow: frequencyTitle, secondRow: frequencyContent))
        cells.append(generateDetailTwoRowCell(firstRow: Localize.string("level_detail_5_title3"), secondRow: String(format: Localize.string("level_detail_5_content3"), data.minCapital.description(), String(data.betMultiple))))
        
        return cells
    }
    
    private func generateDetailOneRowCell(leftContent: String, RightContent: String) -> UITableViewCell {
        let detailCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetailTableViewCell") as! LevelDetailTableViewCell
        detailCell.leftLabel.text = leftContent
        detailCell.rightLabel.text = RightContent
        return detailCell
    }
    
    private func generateDetailTwoRowCell(firstRow: String, secondRow: String) -> UITableViewCell {
        let detail2RowCell = tableView.dequeueReusableCell(withIdentifier: "LevelDetail2TableViewCell") as! LevelDetail2TableViewCell
        detail2RowCell.titleLabel.text = firstRow
        detail2RowCell.secondLabel.text = secondRow
        return detail2RowCell
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
