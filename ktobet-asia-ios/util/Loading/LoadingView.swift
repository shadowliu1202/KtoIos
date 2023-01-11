import UIKit

class LoadingView: UIView {
    private let imageView = UIImageView(image: .init(named: "icon.loading") ?? .init())
    
    init() {
        super.init(frame: .zero)
        isHidden = true
        backgroundColor = .gray131313.withAlphaComponent(0.8)
        
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(64)
        }
        
        addLayerAnimation(to: imageView.layer, duration: 1)
    }

    private func addLayerAnimation(to layer: CALayer, duration: Double) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.fromValue = 0
        animation.toValue = Double.pi * 2
        animation.duration = CFTimeInterval(duration)
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        layer.add(animation, forKey: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
