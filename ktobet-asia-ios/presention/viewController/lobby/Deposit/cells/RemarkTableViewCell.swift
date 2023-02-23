import RxSwift
import SDWebImage
import SharedBu
import UIKit

protocol RemarkTableCellCallback: AnyObject {
  func refreshTableView()
}

class RemarkTableViewCell: UITableViewCell {
  @IBOutlet private weak var dateLabel: UILabel!
  @IBOutlet private weak var remarkLabel: UILabel!
  @IBOutlet private weak var imagesViewHeight: NSLayoutConstraint!
  @IBOutlet private weak var img1: UIImageView!
  @IBOutlet private weak var img2: UIImageView!
  @IBOutlet private weak var img3: UIImageView!
  weak var delegate: RemarkTableCellCallback?
  var toBigImage: ((String, UIImage?) -> Void)?
  private var disposeBag = DisposeBag()

  func setup(history: Transaction.StatusChangeHistory, httpClient: HttpClient) {
    let imgs = [img1, img2, img3]
    imgs.forEach { $0?.isHidden = true }
    dateLabel.text = history.createdDate.toDateTimeString()
    let remarkLevel1 = history.remarkLevel1.count != 0 ? history.remarkLevel1 + " > " : ""
    let remarkLevel2 = history.remarkLevel2.count != 0 ? history.remarkLevel2 + " > " : ""
    let remarkLevel3 = history.remarkLevel3.count != 0 ? history.remarkLevel3 + " > " : ""
    let remark = remarkLevel1 + remarkLevel2 + remarkLevel3
    remarkLabel.text = String(remark.dropLast(2))
    imageView?.isHidden = history.imageIds.count == 0
    imagesViewHeight.constant = history.imageIds.count == 0 ? 0 : 96
    let imageDownloader = SDWebImageDownloader.shared
    for header in httpClient.headers {
      imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
    }

    for (index, img) in history.imageIds.enumerated() {
      if let imgs = imgs[safe: index] {
        imgs?.isHidden = false
        imgs?.tag = index
        imgs?.sd_setImage(
          url: URL(string: img.thumbnailLink() + ".jpg"),
          placeholderImage: nil,
          completed: { [weak self] _, _, _, _ in
            self?.delegate?.refreshTableView()
          })
        imgs?.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer()
        imgs?.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { [weak self] _ in
          self?.toBigImage?(img.link(), imgs?.image)
        }).disposed(by: disposeBag)
      }
    }
  }

  func setup(history: UpdateHistory, httpClient: HttpClient) {
    let imgs = [img1, img2, img3]
    imgs.forEach { $0?.isHidden = true }
    dateLabel.text = history.createdDate.toDateTimeString()
    let remarkLevel1 = history.remarkLevel1.count != 0 ? history.remarkLevel1 + " > " : ""
    let remarkLevel2 = history.remarkLevel2.count != 0 ? history.remarkLevel2 + " > " : ""
    let remarkLevel3 = history.remarkLevel3.count != 0 ? history.remarkLevel3 + " > " : ""
    let remark = remarkLevel1 + remarkLevel2 + remarkLevel3
    remarkLabel.text = String(remark.dropLast(2))
    imageView?.isHidden = history.imageIds.count == 0
    imagesViewHeight.constant = history.imageIds.count == 0 ? 0 : 96
    let imageDownloader = SDWebImageDownloader.shared
    for header in httpClient.headers {
      imageDownloader.setValue(header.value, forHTTPHeaderField: header.key)
    }

    for (index, img) in history.imageIds.enumerated() {
      if let imgs = imgs[safe: index] {
        imgs?.isHidden = false
        imgs?.tag = index
        let urlString = httpClient.host.absoluteString + img.thumbnailPath() + ".jpg"
        imgs?.sd_setImage(url: URL(string: urlString), placeholderImage: nil, completed: { [weak self] _, _, _, _ in
          self?.delegate?.refreshTableView()
        })
        imgs?.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer()
        imgs?.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: { [weak self] _ in
          let urlString = httpClient.host.absoluteString
          let pathString = urlString + img.path()
          self?.toBigImage?(pathString, imgs?.image)
        }).disposed(by: disposeBag)
      }
    }
  }
}

extension UIImageView {
  func enableZoom() {
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
    isUserInteractionEnabled = true
    addGestureRecognizer(pinchGesture)
  }

  @objc
  private func startZooming(_ sender: UIPinchGestureRecognizer) {
    let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
    guard let scale = scaleResult, scale.a > 1, scale.d > 1 else { return }
    sender.view?.transform = scale
    sender.scale = 1
  }
}
