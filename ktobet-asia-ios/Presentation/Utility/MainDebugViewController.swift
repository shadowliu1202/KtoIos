
import Moya
import RxCocoa
import RxSwift
import UIKit

struct DebugData {
  let debugCharCount = 500

  var callbackTime: String?
  var url: String?
  var headers: String?
  var body: String?
  var error: String?
  var response: String?
  var hideHeader = true

  private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.calendar = Calendar(identifier: .iso8601)
    dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter
  }()

  init(
    callbackTime: String? = nil,
    url: String? = nil,
    headers: String? = nil,
    body: String? = nil,
    error: String? = nil,
    response: String? = nil)
  {
    self.callbackTime = callbackTime
    self.url = url
    self.headers = headers
    self.body = body
    self.error = error
    self.response = response
  }

  init(moyaResponse: Response) {
    self.callbackTime = dateFormatter.string(from: Date())

    if let url = moyaResponse.request?.url {
      self.url = url.absoluteString
    }

    if let headers = moyaResponse.request?.allHTTPHeaderFields {
      self.headers = "\(headers)"
    }

    if
      let body = moyaResponse.request?.httpBody,
      let bodyString = String(data: body, encoding: .utf8)
    {
      let replaced = bodyString.replacingOccurrences(of: "\\", with: "")
      self.body = replaced.count < debugCharCount ? replaced : replaced.prefix(debugCharCount) + "...more"
    }

    if let dataString = String(data: moyaResponse.data, encoding: .utf8) {
      self.response = dataString.count < debugCharCount ? dataString : dataString.prefix(debugCharCount) + "...more"
    }
    else {
      self.response = "response is empty"
    }
  }
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
  private let httpClient = Injectable.resolve(HttpClient.self)!
  private var isLoadApi = true

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupBinding()
    loadApi()
  }

  @IBAction
  func clickSwitch(_: Any) {
    isLoadApi.toggle()
    if isLoadApi {
      loadApi()
      switchBtn.setTitle("看Log", for: .normal)
      cleanBtn.setTitle("", for: .normal)
    }
    else {
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
    }
    catch {
      Logger.shared.debug(error.localizedDescription)
    }
  }

  @IBAction
  func clickClean(_: Any) {
    do {
      let fileURL = PuppyLog.shared.fileURL
      try "".write(to: fileURL, atomically: false, encoding: .utf8)
    }
    catch {
      Logger.shared.debug(error.localizedDescription)
    }

    loadLogFile()
  }

  private func setCell(
    cell: MainDebugDataCell,
    callbackTime: String?,
    url: String?,
    headers: String?,
    body: String?,
    error: String?,
    response: String?)
  {
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
    debugDatas.bind(to: tableView.rx.items) { tableView, _, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: "MainDebugDataCell", cellType: MainDebugDataCell.self)
      cell.configure(
        callbackTime: item.callbackTime,
        url: item.url,
        headers: item.headers,
        body: item.body,
        error: item.error,
        response: item.response,
        hideHeader: item.hideHeader)
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
    Logger.shared.info("\(type(of: self)) deinit")
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

  func configure(
    callbackTime: String?,
    url: String?,
    headers: String?,
    body: String?,
    error: String?,
    response: String?,
    hideHeader: Bool?)
  {
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
