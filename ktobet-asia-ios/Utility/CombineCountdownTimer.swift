import Combine
import Foundation

class CombineCountdownTimer {
    private var timer: AnyCancellable?
    private var timeRemaining = 0

    func start(
        seconds: Int,
        onTick: @escaping (_ timeRemaining: Int) -> Void,
        completion: @escaping () -> Void)
    {
        timer?.cancel()

        timeRemaining = seconds

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    onTick(self.timeRemaining)
                }
                else {
                    self.timer?.cancel()
                    completion()
                }
            }
    }

    func stop() {
        timer?.cancel()
    }
}
