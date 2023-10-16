import AVFoundation
import UIKit

private enum VideoPlayError: Error {
  case assetLoadingFailed
  case itemStatusFailed
  case itemStatusUnknown
}

class VideoView: UIView {
  private var player: AVPlayer? {
    get { playerLayer.player }
    set { playerLayer.player = newValue }
  }

  private var observer: NSKeyValueObservation?

  var playerLayer: AVPlayerLayer {
    layer as! AVPlayerLayer
  }

  override class var layerClass: AnyClass {
    AVPlayerLayer.self
  }
  
  deinit {
    self.observer?.invalidate()
    self.observer = nil
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func play(with url: URL) async throws {
    let asset = try await loadPlayerAsset(with: url)
    let item = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: item)
    
    let statusStream = AsyncStream { continuation in
      observer = item.observe(\AVPlayerItem.status, options: [.old, .new]) { item, _ in
        continuation.yield(item.status)
      }
    }
    
    for await status in statusStream {
      switch status {
      case .readyToPlay:
        await waitForPlaybackCompletion(item)
        return
      case .unknown:
        continue
      case .failed:
        throw VideoPlayError.itemStatusFailed
      @unknown default:
        throw VideoPlayError.itemStatusUnknown
      }
    }
  }

  private func loadPlayerAsset(with url: URL) async throws -> AVAsset {
    let asset = AVAsset(url: url)
    
    return try await withCheckedThrowingContinuation { continuation in
      asset.loadValuesAsynchronously(forKeys: ["playable"]) {
        var error: NSError?
        let status = asset.statusOfValue(forKey: "playable", error: &error)
        if status == .loaded {
          continuation.resume(returning: asset)
        }
        else {
          continuation.resume(throwing: VideoPlayError.assetLoadingFailed)
        }
      }
    }
  }

  private func waitForPlaybackCompletion(_ item: AVPlayerItem) async {
    await withCheckedContinuation { continuation in
      NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: item,
        queue: nil,
        using: { _ in
          continuation.resume()
        })
      
      player?.play()
    }
  }
}
