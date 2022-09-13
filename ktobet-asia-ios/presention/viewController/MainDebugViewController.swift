
import UIKit
import RxSwift
import RxCocoa

struct DebugData {
    var callbackTime: String? = nil
    var url: String? = nil
    var headers: String? = nil
    var body: String? = nil
    var error: String? = nil
    var response: String? = nil
    var hideHeader: Bool = true
}

class MainDebugViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var switchBtn: UIButton!
    @IBOutlet weak var cleanBtn: UIButton!
    
    @IBOutlet weak var itemViewHeight: NSLayoutConstraint!
    var cancelHandle: (() -> Void)?
    
    private var debugDatas = BehaviorRelay<[DebugData]>(value: [])
    private lazy var disposeBag = DisposeBag()
    private let httpClient = DI.resolve(HttpClient.self)!
    private var isLoadApi = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupBinding()
        loadApi()
    }
    
    @IBAction func clickSwitch(_ sender: Any) {
        isLoadApi.toggle()
        if isLoadApi {
            loadApi()
            switchBtn.setTitle("看Log", for: .normal)
            cleanBtn.setTitle("", for: .normal)
        } else {
            loadLogFile()
            switchBtn.setTitle("看Api", for: .normal)
            cleanBtn.setTitle("清除Log", for: .normal)
        }
    }
    
    private func loadApi() {
        loadData(httpClient.debugDatas.reversed())
    }
    
    private func loadLogFile() {
        do {
            let fileURL = PuppyLog.shared.fileURL
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            let data = [DebugData(response: text2)]
            loadData(data)
        } catch {
            print(error)
        }
    }
    
    @IBAction func clickClean(_ sender: Any) {
        do {
            let fileURL = PuppyLog.shared.fileURL
            try "".write(to: fileURL, atomically: false, encoding: .utf8)
        } catch {
            print(error)
        }
        
        loadLogFile()
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
