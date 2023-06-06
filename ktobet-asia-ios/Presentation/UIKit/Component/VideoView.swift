import AVFoundation
import UIKit

class VideoView: UIView {
  private var player: AVPlayer? {
    get {
      playerLayer.player
    }
    set {
      playerLayer.player = newValue
    }
  }

  private var observer: NSKeyValueObservation?
  private var didFail: (() -> Void)?

  var playerLayer: AVPlayerLayer {
    layer as! AVPlayerLayer
  }

  override class var layerClass: AnyClass {
    AVPlayerLayer.self
  }

  func play(with url: URL, fail: (() -> Void)?) {
    self.didFail = fail
    initPlayerAsset(with: url) { (asset: AVAsset) in
      let item = AVPlayerItem(asset: asset)
      self.observer = item.observe(\AVPlayerItem.status, options: [.old, .new]) { [weak self] item, _ in
        switch item.status {
        case .readyToPlay:
          self?.player?.play()
        case .failed,
             .unknown:
          self?.didFail?()
        @unknown default:
          self?.didFail?()
        }
      }
      DispatchQueue.main.async {
        self.player = AVPlayer(playerItem: item)
      }
    }
  }

  private func initPlayerAsset(with url: URL, completion: ((_ asset: AVAsset) -> Void)?) {
    let asset = AVAsset(url: url)
    asset.loadValuesAsynchronously(forKeys: ["playable"]) {
      completion?(asset)
    }
  }

  deinit {
    self.observer?.invalidate()
    self.observer = nil
    Logger.shared.info("\(type(of: self)) deinit")
  }
}
