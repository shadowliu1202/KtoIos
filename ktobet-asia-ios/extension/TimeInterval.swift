import Foundation

extension TimeInterval {
    func timeRemainingFormatted() -> String {
        let duration = TimeInterval(self)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter.string(from: duration) ?? ""
    }
}

extension Timer {
    func setTimerMode(mode: RunLoop.Mode = .common) {
        RunLoop.main.add(self, forMode: mode)
    }
}
