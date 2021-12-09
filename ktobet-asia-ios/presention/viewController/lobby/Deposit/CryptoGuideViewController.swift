import UIKit

class CryptoGuideViewController: UIViewController {
    static let segueIdentifier = "toCryptoGuide"
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    private var unsettleds: [Market] = [Market("币安"), Market("欧易")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
    }
    
    private func initUI() {
        descriptionLabel.text = """
        以下是新用户可以购买虚拟币的交易所列表。

        我们尽量保持信息更新，但我们不对客户在各交易所探索过程中出现的不准确信息或任何损失负责。

        如果对交易所使用有任何疑问或问题，建议您直接联交易所客服。
        """
        tableView.layoutTableHeaderView()
        tableView.setDivider(dividerColor: .clear)
        tableView.estimatedRowHeight = 36.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 238.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
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
        return unsettleds.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return unsettleds[section].guides.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "GuideViewCell", cellType: GuideViewCell.self).configure(unsettleds[indexPath.section].guides[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (unsettleds[indexPath.section].expanded) {
            return 36
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooter(withIdentifier: "MarketHeaderView", cellType: MarketHeaderView.self).configure(unsettleds[section], callback: { [unowned self] (header) in
            self.unsettleds[section].expanded.toggle()
            header.icon?.image = self.unsettleds[section].expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
            self.reloadRows(at: section, rowCount: unsettleds[section].guides.count, with: .automatic)
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = unsettleds[indexPath.section].guides[indexPath.row]
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
    private(set) var guides: [Guide] = [Guide](repeating: Guide(), count: 6)
    var expanded: Bool = false
    
    init(_ name: String) {
        self.name = name
    }
}

struct Guide {
    @DummyValue(wrappedValue: "币安新用户指引")
    var name: String
    @DummyValue(wrappedValue: "https://www.google.com")
    var link: String
}

@propertyWrapper
struct DummyValue<Value> {
    private var value: Value
    var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}
