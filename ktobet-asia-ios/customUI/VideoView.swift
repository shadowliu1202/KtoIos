import UIKit
import AVFoundation

class VideoView: UIView {

    private var playerItemContext = 0
    private var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    private var didFail: (() -> Void)?
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    func play(with url: URL, fail: (() -> ())?) {
        self.didFail = fail
        initPlayerAsset(with: url) { (asset: AVAsset) in
            let item = AVPlayerItem(asset: asset)
            item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &self.playerItemContext)
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                self.player?.play()
            case .failed, .unknown:
                self.didFail?()
            @unknown default:
                self.didFail?()
            }
        }
    }

    deinit {
        print("\(type(of: self)) deinit")
    }
}
