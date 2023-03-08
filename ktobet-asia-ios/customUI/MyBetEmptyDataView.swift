import Foundation
import UIKit

class MyBetEmptyDataView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  func setup() {
    let noRecordsIcon = UIImageView(image: UIImage(named: "fill1Copy"))
    noRecordsIcon.contentMode = .scaleAspectFit
    noRecordsIcon.snp.makeConstraints { make in
      make.width.height.equalTo(90)
    }

    let noRecordsLabel = UILabel()
    noRecordsLabel.text = Localize.string("product_none_my_bet_record")
    noRecordsLabel.textColor = .gray9B9B9B
    noRecordsLabel.font = UIFont(name: "PingFangSC-Medium", size: 16)

    let vStack = UIStackView(
      arrangedSubviews: [
        noRecordsIcon,
        noRecordsLabel
      ],
      spacing: 15,
      distribution: .fill,
      alignment: .center)

    addSubview(vStack)
    vStack.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(-50)
    }
  }
}
