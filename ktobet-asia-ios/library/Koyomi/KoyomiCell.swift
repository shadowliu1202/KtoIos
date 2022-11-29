//
//  KoyomiCell.swift
//  Pods
//
//  Created by Shohei Yokoyama on 2016/10/09.
//
//

import UIKit

final class KoyomiCell: UICollectionViewCell {
    
    // Fileprivate properties
    fileprivate let contentLabel: UILabel = .init()
    fileprivate let circularView: UIView  = .init()
    fileprivate let lineView: UIView      = .init()
    
    fileprivate let leftSemicircleView: UIView  = .init()
    fileprivate let rightSemicircleView: UIView = .init()
    
    static let identifier = "KoyomiCell"
    
    enum CellStyle {
        case standard, circle, semicircleEdge(position: SequencePosition), line(position: SequencePosition?)
        
        enum SequencePosition { case left, middle, right }
    }
    
    // Internal properties
    var content = "" {
        didSet {
            contentLabel.text = content
            adjustSubViewsFrame()
        }
    }
    var textColor: UIColor = UIColor.KoyomiColor.black {
        didSet {
            contentLabel.textColor = textColor
            xLabel.textColor = textColor
        }
    }
    var dayBackgroundColor: UIColor = .white {
        didSet {
            backgroundColor = dayBackgroundColor
        }
    }
    var contentPosition: ContentPosition = .center
    
    var lineViewAppearance: Koyomi.LineView? {
        didSet {
            configureLineView()
        }
    }
    var circularViewDiameter: CGFloat = 0.75 {
        didSet {
            configureCircularView()
        }
    }
    
    // MARK: - Initializer -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustSubViewsFrame()
    }
    
    // MARK: - Internal Methods -
    
    func setContentFont(fontName name: String, size: CGFloat) {
        contentLabel.font = UIFont(name: name, size: size)
        adjustSubViewsFrame()
    }

    let xLabel = UILabel()
    func configureAppearanse(of style: CellStyle, withColor color: UIColor, backgroundColor: UIColor, isSelected: Bool, model: DateModel) {
        switch style {
        case .standard:
            self.backgroundColor = isSelected ? color : backgroundColor
            circularView.isHidden  = true
            lineView.isHidden = true
            rightSemicircleView.isHidden = true
            leftSemicircleView.isHidden  = true
            self.isUserInteractionEnabled = xLabel.text == ""
        // isSelected is always true
        case .circle:
            circularView.backgroundColor = color
            self.backgroundColor = backgroundColor
            
            circularView.isHidden  = false
            lineView.isHidden = true
            rightSemicircleView.isHidden = true
            leftSemicircleView.isHidden  = true
            contentLabel.textColor = UIColor.black
        // isSelected is always true
        case .semicircleEdge(let position):
            lineView.isHidden = true
            circularView.isHidden = true
            self.backgroundColor = backgroundColor
            if case .left = position {
                circularView.backgroundColor = color
                circularView.isHidden  = false
                self.bringSubviewToFront(circularView)
                self.bringSubviewToFront(contentLabel)
            } else if case .middle = position {
                rightSemicircleView.isHidden = false
                leftSemicircleView.isHidden  = false
                leftSemicircleView.backgroundColor = .yellowFFD500.withAlphaComponent(0.3)
                rightSemicircleView.backgroundColor = .yellowFFD500.withAlphaComponent(0.3)
                
                let lastSelectedDate = model.getSelectedDates()
                let formatter = DateFormatter()
                formatter.dateFormat = "d"
                let lastday = formatter.string(from: lastSelectedDate.first!)
                let firstday = formatter.string(from: lastSelectedDate.last!)
                if lastday == contentLabel.text {
                    rightSemicircleView.backgroundColor = backgroundColor
                    circularView.backgroundColor = color
                    circularView.isHidden  = false
                    self.bringSubviewToFront(circularView)
                    self.bringSubviewToFront(contentLabel)
                }
                
                if firstday == contentLabel.text && lastSelectedDate.count == 7 {
                    leftSemicircleView.backgroundColor = backgroundColor
                    circularView.backgroundColor = color
                    circularView.isHidden  = false
                    self.bringSubviewToFront(circularView)
                    self.bringSubviewToFront(contentLabel)
                }
                
                contentLabel.textColor = UIColor.black
            } else if case .right = position {
                circularView.backgroundColor = color
                circularView.isHidden  = false
                self.bringSubviewToFront(circularView)
                self.bringSubviewToFront(contentLabel)
            }
            
            contentLabel.textColor = UIColor.black
        case .line(let position):
            rightSemicircleView.isHidden = true
            leftSemicircleView.isHidden  = true
            circularView.isHidden = true
            lineView.isHidden = false
            lineView.backgroundColor = color
            
            // Config of lineView should end. (configureLineView())
            // position is only sequence style
            guard let position = position else {
                lineView.frame.origin.x = (bounds.width - lineView.frame.width) / 2
                return
            }
            switch position {
            case .left:
                lineView.frame.origin.x = bounds.width - lineView.frame.width
            case .middle:
                lineView.frame.size.width = bounds.width
                lineView.frame.origin.x   = (bounds.width - lineView.frame.width) / 2
            case .right:
                lineView.frame.origin.x = 0
            }
        }
    }
}

// MARK: - Private Methods

private extension KoyomiCell {
    var postion: CGPoint {
        let dayWidth  = contentLabel.frame.width
        let dayHeight = contentLabel.frame.height
        let width  = frame.width
        let height = frame.height
        let padding: CGFloat = 2
        
        switch contentPosition {
        // Top
        case .topLeft:   return .init(x: padding, y: padding)
        case .topCenter: return .init(x: (width - dayWidth) / 2, y: padding)
        case .topRight:  return .init(x: width - dayWidth - padding, y: padding)
        // Center
        case .left:   return .init(x: padding, y: (height - dayHeight) / 2)
        case .center: return .init(x: (width - dayWidth) / 2, y: (height - dayHeight) / 2)
        case .right:  return .init(x: width - dayWidth - padding, y: (height - dayHeight) / 2)
        // Bottom
        case .bottomLeft:   return .init(x: padding, y: height - dayHeight - padding)
        case .bottomCenter: return .init(x: (width - dayWidth) / 2, y: height - dayHeight - padding)
        case .bottomRight:  return .init(x: width - dayWidth - padding, y: height - dayHeight - padding)
        // Custom
        case .custom(let x, let y): return .init(x: x, y: y)
        }
    }
    
    func setup() {
        circularView.isHidden = true
        addSubview(circularView)

        leftSemicircleView.frame = CGRect(x: 0, y: 2, width: bounds.width / 2, height: bounds.height - 4)
        leftSemicircleView.isHidden = true
        leftSemicircleView.backgroundColor = .yellowFFD500.withAlphaComponent(0.3)
        addSubview(leftSemicircleView)
                
        rightSemicircleView.frame = CGRect(x: bounds.width / 2, y: 2, width: bounds.width / 2, height: bounds.height - 4)
        rightSemicircleView.isHidden = true
        rightSemicircleView.backgroundColor = .yellowFFD500.withAlphaComponent(0.3)
        addSubview(rightSemicircleView)
        
        addSubview(contentLabel)
        addSubview(xLabel)
        
        let lineViewSize: CGSize = .init(width: bounds.width, height: 1)
        lineView.frame = CGRect(origin: .init(x: 0, y: (bounds.height - lineViewSize.height) / 2), size: lineViewSize)
        lineView.isHidden = true
        addSubview(lineView)
    }
    
    func adjustSubViewsFrame() {
        contentLabel.sizeToFit()
        contentLabel.frame.origin = postion
        xLabel.font = UIFont.systemFont(ofSize: 10)
        xLabel.textAlignment = .center
        xLabel.sizeToFit()
        xLabel.frame = CGRect(x: postion.x, y: postion.y + contentLabel.frame.height - 2, width: contentLabel.frame.width, height: contentLabel.frame.height)
        
        rightSemicircleView.frame = CGRect(x: bounds.width / 2, y: 2, width: bounds.width / 2, height: bounds.height - 4)
        leftSemicircleView.frame  = CGRect(x: 0, y: 2, width: bounds.width / 2, height: bounds.height - 4)
    }
    
    func configureCircularView() {
        let diameter = bounds.width * circularViewDiameter
        circularView.frame = CGRect(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2, width: diameter, height: diameter)
        circularView.layer.cornerRadius = diameter / 2
    }
    
    func configureLineView() {
        guard let appearance = lineViewAppearance else { return }
        lineView.frame.size = CGSize(width: bounds.width * appearance.widthRate, height: appearance.height)
        lineView.frame.origin.y = {
            switch appearance.position {
            case .top:    return (bounds.height / 2 - lineView.frame.height) / 2
            case .center: return (bounds.height - lineView.frame.height) / 2
            case .bottom: return (bounds.height / 2 - lineView.frame.height) / 2 + bounds.height / 2
            }
        }()
    }
}
