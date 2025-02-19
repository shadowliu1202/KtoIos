import Foundation
import UIKit

protocol SegmentedProgressBarDelegate: AnyObject {
  func segmentedProgressBarChangedIndex(index: Int)
  func segmentedProgressBarFinished()
}

class SegmentedProgressBar: UIView {
  weak var delegate: SegmentedProgressBarDelegate?
  var topColor = UIColor.statusSuccess {
    didSet {
      self.updateColors()
    }
  }

  var bottomColor = UIColor.textPrimary {
    didSet {
      self.updateColors()
    }
  }

  var padding: CGFloat = 2
  var isPaused = false {
    didSet {
      if isPaused {
        for segment in segments {
          let layer = segment.topSegmentView.layer
          let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
          layer.speed = 0.0
          layer.timeOffset = pausedTime
        }
      }
      else {
        let segment = segments[currentAnimationIndex]
        let layer = segment.topSegmentView.layer
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
      }
    }
  }

  private var percentage: Double = 0
  private var segments = [Segment]()
  private let duration: TimeInterval
  private var hasDoneLayout = false // hacky way to prevent layouting again
  private var currentAnimationIndex = -1
  private var numberOfSegments = 0

  init(numberOfSegments: Int, percentage: Double, duration: TimeInterval = 5.0) {
    self.duration = duration
    self.numberOfSegments = numberOfSegments
    self.percentage = percentage
    super.init(frame: CGRect.zero)

    for _ in 0..<numberOfSegments {
      let segment = Segment()
      addSubview(segment.bottomSegmentView)
      addSubview(segment.topSegmentView)
      segments.append(segment)
    }
    self.updateColors()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if hasDoneLayout {
      return
    }

    let width: CGFloat = (frame.width - (padding * CGFloat(segments.count - 1))) / CGFloat(segments.count)
    for (index, segment) in segments.enumerated() {
      let segFrame = CGRect(x: CGFloat(index) * (width + padding), y: 0, width: width, height: frame.height)
      segment.bottomSegmentView.frame = segFrame
      segment.topSegmentView.frame = segFrame
      segment.topSegmentView.frame.size.width = 0
    }

    hasDoneLayout = true
  }

  func startAnimation() {
    layoutSubviews()
    let percentageOf100 = 100.0 / Double(numberOfSegments)
    let multiple = Int(percentage / percentageOf100)
    for _ in 0..<multiple {
      self.next()
    }
  }

  private func animate(animationIndex: Int = 0) {
    let nextSegment = segments[animationIndex]
    currentAnimationIndex = animationIndex
    self.isPaused = false // no idea why we have to do this here, but it fixes everything :D
    UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
      nextSegment.topSegmentView.frame.size.width = nextSegment.bottomSegmentView.frame.width
    }) { finished in
      if !finished {
        return
      }
      self.next()
    }
  }

  private func updateColors() {
    for segment in segments {
      segment.topSegmentView.backgroundColor = topColor
      segment.bottomSegmentView.backgroundColor = bottomColor
    }
  }

  func next() {
    let newIndex = self.currentAnimationIndex + 1
    if newIndex < self.segments.count {
      self.animate(animationIndex: newIndex)
      self.delegate?.segmentedProgressBarChangedIndex(index: newIndex)
    }
    else {
      self.delegate?.segmentedProgressBarFinished()
    }
  }

  func skip() {
    let currentSegment = segments[currentAnimationIndex]
    currentSegment.topSegmentView.frame.size.width = currentSegment.bottomSegmentView.frame.width
    currentSegment.topSegmentView.layer.removeAllAnimations()
    self.next()
  }

  func rewind() {
    let currentSegment = segments[currentAnimationIndex]
    currentSegment.topSegmentView.layer.removeAllAnimations()
    currentSegment.topSegmentView.frame.size.width = 0
    let newIndex = max(currentAnimationIndex - 1, 0)
    let prevSegment = segments[newIndex]
    prevSegment.topSegmentView.frame.size.width = 0
    self.animate(animationIndex: newIndex)
    self.delegate?.segmentedProgressBarChangedIndex(index: newIndex)
  }
}

private class Segment {
  let bottomSegmentView = UIView()
  let topSegmentView = UIView()
  init() {
    bottomSegmentView.masksToBounds = true
    bottomSegmentView.cornerRadius = 1
    topSegmentView.masksToBounds = true
    topSegmentView.cornerRadius = 1
  }
}
