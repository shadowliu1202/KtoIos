import SharedBu
import UIKit

struct RouletteGameResultBuilder: CasinoResultBuilder {
  let roulette: CasinoGameResult.Roulette
  
  func build(to background: UIView) {
    let label = UILabel()
    label.text = String(roulette.result)
    label.font = UIFont(name: "PingFangTC-Semibold", size: 18)
    label.textColor = UIColor.whitePure
    label.textAlignment = .center
    label.backgroundColor = .redF20000
    label.cornerRadius = 20

    background.addSubview(label)
    label.snp.makeConstraints { make in
      make.size.equalTo(40)
      make.centerX.equalToSuperview()
      make.centerY.equalTo(30)
    }

    background.snp.makeConstraints { make in
      make.height.equalTo(90)
    }

    background.addBorder(.bottom)
  }
}

