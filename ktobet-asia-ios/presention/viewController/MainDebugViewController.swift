
import UIKit
import RxSwift
import RxCocoa

struct DebugData {
    var callbackTime: String?
    var url: String?
    var headers: String?
    var body: String?
    var error: String?
    var response: String?
    var hideHeader: Bool = true
}

class MainDebugViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var itemViewHeight: NSLayoutConstraint!
    var cancelHandle: (() -> Void)?
    
    private var debugDatas = BehaviorRelay<[DebugData]>(value: [])
    private lazy var disposeBag = DisposeBag()
    private let httpClient = DI.resolve(HttpClient.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupBinding()
        loadData(httpClient.debugDatas.reversed())
    }
    
    private func setCell(cell:MainDebugDataCell, callbackTime: String?, url: String?, headers: String?, body: String?, error: String?, response: String?) {
        
        cell.callbackTimeRowStackView.isHidden = callbackTime == nil
        cell.urlRowStackView.isHidden = url == nil
        cell.headersRowStackView.isHidden = headers == nil
        cell.bodyRowStackView.isHidden = body == nil
        
        cell.errorImageView.isHidden = error == nil

        cell.callbackTimeLabel.text = callbackTime
        cell.urlLabel.text = url
        cell.headersLabel.text = headers
        cell.responseLabel.textColor = error != nil ? UIColor(hex: 0xff0000) : UIColor(hex: 0x000000)
        cell.responseLabel.text = error != nil ? error : response
        cell.bodyLabel.text = body
        
    }

    private func setupBinding() {
        debugDatas.bind(to: tableView.rx.items) { tableView, row, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "MainDebugDataCell", cellType: MainDebugDataCell.self)
            cell.configure(callbackTime: item.callbackTime, url: item.url, headers: item.headers, body: item.body, error: item.error, response: item.response, hideHeader: item.hideHeader)
            return cell
        }.disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.bind(onNext: { [unowned self] indexPath in
            self.refreshData(indexPath.row)
        }).disposed(by: self.disposeBag)
        
        self.cancelButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            self?.cancelHandle?()
        }).disposed(by: self.disposeBag)
    }
    
    private func loadData(_ logs: [DebugData]) {
        debugDatas.accept(logs)
    }
    
    private func refreshData(_ row: Int) {
        var copyValue = self.debugDatas.value
        var data = copyValue[row]
        data.hideHeader.toggle()
        copyValue.remove(at: row)
        copyValue.insert(data, at: row)
        self.debugDatas.accept(copyValue)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

class MainDebugDataCell: UITableViewCell {
    @IBOutlet weak var callbackTimeRowStackView: UIStackView!
    @IBOutlet weak var urlRowStackView: UIStackView!
    @IBOutlet weak var headersRowStackView: UIStackView!
    @IBOutlet weak var bodyRowStackView: UIStackView!
    @IBOutlet weak var responseRowStackView: UIStackView!
    
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var callbackTimeLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var headersLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var responseLabel: UILabel!
    
    func configure(callbackTime: String?, url: String?, headers: String?, body: String?, error: String?, response: String?, hideHeader: Bool?) {
        callbackTimeRowStackView.isHidden = callbackTime == nil
        urlRowStackView.isHidden = url == nil
        headersRowStackView.isHidden = headers == nil
        bodyRowStackView.isHidden = body == nil
        errorImageView.isHidden = error == nil
        callbackTimeLabel.text = callbackTime
        urlLabel.text = url
        headersLabel.text = headers
        headersRowStackView.isHidden = hideHeader ?? true
        responseLabel.textColor = error != nil ? UIColor(hex: 0xff0000) : UIColor(hex: 0x000000)
        responseLabel.text = error != nil ? error : response
        bodyLabel.text = body
    }
    
}
