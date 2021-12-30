import UIKit
import RxSwift

class CryptoGuideViewController: UIViewController {
    static let segueIdentifier = "toCryptoGuide"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    private var viewModel = DI.resolve(TermsViewModel.self)!
    private var resources: [Market] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        bindData()
    }
    
    private func initUI() {
        tableView.setDivider(dividerColor: .clear)
        tableView.estimatedRowHeight = 36.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 238.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func bindData() {
        viewModel.cryptoGuidance.subscribe(onSuccess: { [weak self] g in
            self?.titleLabel.text = Localize.string("cps_crypto_currency_guide_title")
            self?.descriptionLabel.text = Localize.string("cps_crypto_guidance_description")
            self?.tableView.layoutTableHeaderView()
            self?.resources = g.map({ Market($0.title, $0.links.map({Guide(name: $0.title, link: $0.link)}))})
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    private func reloadRows(at sectionIndex: Int, rowCount: Int, with animation: UITableView.RowAnimation) {
        self.tableView.beginUpdates()
        for i in 0 ..< rowCount {
            self.tableView.reloadRows(at: [IndexPath(row: i, section: sectionIndex)], with: .automatic)
        }
        self.tableView.endUpdates()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension CryptoGuideViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return resources.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resources[section].guides.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "GuideViewCell", cellType: GuideViewCell.self).configure(resources[indexPath.section].guides[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (resources[indexPath.section].expanded) {
            return 36
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooter(withIdentifier: "MarketHeaderView", cellType: MarketHeaderView.self).configure(resources[section], callback: { [unowned self] (header) in
            self.resources[section].expanded.toggle()
            header.icon?.image = self.resources[section].expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
            self.reloadRows(at: section, rowCount: resources[section].guides.count, with: .automatic)
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = resources[indexPath.section].guides[indexPath.row]
        guard let url = URL(string: item.link) else { return }
        UIApplication.shared.open(url)
    }
    
}

class GuideViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(_ item: Guide) -> Self {
        self.selectionStyle = .none
        titleLabel.text = item.name
        return self
    }
}


class Market {
    var name: String
    var guides: [Guide]
    var expanded: Bool = false
    init(_ name: String, _ guides: [Guide] = []) {
        self.name = name
        self.guides = guides
    }
}

struct Guide {
    var name: String
    var link: String
}
