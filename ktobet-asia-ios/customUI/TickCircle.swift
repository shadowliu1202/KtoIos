import UIKit


class TickCircle {
    private var ticks: [UIView] = []
    private var backgroundTicks: [UIView] = []
    private var view: UIView
    private let countDownTimer: CountDownTimer?
    private let max_count_down_milliseconds = 5 * 24 * 60 * 60
    private var circle: UIView!
    private var timeLabel: UILabel!
    private var countDownSecond: Int = 0
    private var backgroundTick: UIView!
    private var tick: UIView!
    
    var finishCountDown: (() -> ())?
    
    init(view: UIView) {
        self.view = view
        self.countDownTimer = CountDownTimer()
    }
    
    func drawTickCircle(diameter: Double, countDownSecond: Int, ticksCount: Int = 60) {
        if circle == nil {
            addCircle(diameter: diameter)
            addTimerLabel()
            if countDownSecond < self.max_count_down_milliseconds {
                drawTicks(count: ticksCount)
                setTimer(countDownSecond: countDownSecond)
            } else {
                updateTimeLabel(over5Day: true)
            }
        }
    }
    
    func remove() {
        circle.removeFromSuperview()
        ticks.forEach{ $0.removeFromSuperview() }
        backgroundTicks.forEach{ $0.removeFromSuperview() }
        view.isHidden = true
    }
    
    private func setTimer(countDownSecond: Int) {
        countDownTimer?.start(timeInterval: 1, duration: TimeInterval(countDownSecond)) { [weak self] (index, countDownSecond, finish) in
            guard let self = self else { return }
            self.countDownSecond = countDownSecond
            self.updateTimeLabel(over5Day: countDownSecond > self.max_count_down_milliseconds)

            if self.firstShow {
                self.caculateTickPosition()
            } else {
                self.ticks[(self.currentIndex) % 60].isHidden.toggle()
                self.currentIndex += 1
            }

            if finish {
                self.remove()
                self.finishCountDown?()
            }
        }
    }
    
    var firstShow = true
    var currentIndex = 0
    
    private func caculateTickPosition() {
        let index = countDownSecond % 60
        let showTickStartIndex = 60 - index
        
        for i in 0..<showTickStartIndex {
            ticks[i].isHidden = true
        }
        
        for i in showTickStartIndex..<60 {
            ticks[i].isHidden = false
        }
        
        firstShow = index != 0
    }
    
    private func addCircle(diameter: Double) {
        circle = UIView(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        circle.backgroundColor = UIColor.clear
        circle.layer.cornerRadius = 100.0
        view.addSubview(circle)
    }
    
    private func drawTicks(count: Int) {
        let radius = circle.frame.size.width * 0.5
        var rotationInDegrees: CGFloat = 0
        
        for i in 0 ..< count {
            tick = createTick(color: .white)
            backgroundTick = createTick(color: UIColor(red: 1, green: 1, blue: 1, alpha: 0.3))
            
            let x = CGFloat(Float(circle.center.x) + Float(radius) * cosf(2 * Float(i) * Float(Double.pi) / Float(count) - Float(Double.pi) / 2))
            let y = CGFloat(Float(circle.center.y) + Float(radius) * sinf(2 * Float(i) * Float(Double.pi) / Float(count) - Float(Double.pi) / 2))
            
            tick.center = CGPoint(x: x, y: y)
            backgroundTick.center = CGPoint(x: x, y: y)
            backgroundTick.transform = CGAffineTransform.identity.rotated(by: rotationInDegrees * .pi / 180.0)
            view.addSubview(backgroundTick)
            tick.transform = CGAffineTransform.identity.rotated(by: rotationInDegrees * .pi / 180.0)
            view.addSubview(tick)
            
            ticks.append(tick)
            backgroundTicks.append(backgroundTick)
            rotationInDegrees = rotationInDegrees + (360.0 / CGFloat(count))
        }
    }
    
    private func addTimerLabel() {
        timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: circle.frame.width, height: circle.frame.height))
        timeLabel.font = UIFont(name: "PingFangSC-Semibold", size: 12)
        timeLabel.textColor = UIColor.white
        timeLabel.textAlignment = .center
        circle.addSubview(timeLabel)
    }
    
    private func updateTimeLabel(over5Day: Bool) {
        if over5Day {
            timeLabel.text = Localize.string("common_long_maintenance")
        } else {
            let hour = String(format: "%02d", (countDownSecond / 3600))
            let minute = String(format: "%02d", (countDownSecond % 3600) / 60)
            timeLabel.text = hour + ":" + minute
        }
    }

    private func createTick(color: UIColor) -> UIView {
        let tick = UIView(frame: CGRect(x: 0, y: 0, width: 2.0, height: 2))
        tick.layer.cornerRadius = 1
        tick.backgroundColor = color
        return tick
    }
}
