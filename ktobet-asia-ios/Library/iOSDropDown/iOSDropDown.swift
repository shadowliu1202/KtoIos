
//
//  iOSDropDown.swift
//
//
//  Created by Jishnu Raj T on 26/04/18.
//  Copyright © 2018 JRiOSdev. All rights reserved.
//
import UIKit

let TableHeaderHeight: CGFloat = 12
let TableFooterHeight: CGFloat = 12
let BubbleSpace: CGFloat = 10
open class DropDown: UITextField {
    enum TablePosition {
        case above
        case under
    }

    // MARK: IBInspectable
    @IBInspectable public var rowHeight: CGFloat = 48
    @IBInspectable public var rowBackgroundColor: UIColor = .white
    @IBInspectable public var rowTextColor: UIColor = .black
    @IBInspectable public var selectedRowColor: UIColor = .cyan
    @IBInspectable public var hideOptionsWhenSelect = true
    @IBInspectable public var isSearchEnable = true {
        didSet {
            addGesture()
        }
    }

    @IBInspectable public var borderColor = UIColor.lightGray {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    @IBInspectable public var listHeight: CGFloat = 264
    @IBInspectable public var arrowSize: CGFloat = 15 {
        didSet {
            let center = arrow.superview!.center
            arrow.frame = CGRect(x: center.x - arrowSize / 2, y: center.y - arrowSize / 2, width: arrowSize, height: arrowSize)
        }
    }

    @IBInspectable public var arrowColor: UIColor = .black {
        didSet {
            arrow.arrowColor = arrowColor
        }
    }

    @IBInspectable public var checkMarkEnabled = true
    @IBInspectable public var handleKeyboard = true

    // MARK: Variables
    fileprivate var tableHeightX: CGFloat = 100
    fileprivate var dataArray = [String]()
    fileprivate var imageArray = [String]()
    fileprivate weak var parentController: UIViewController?
    fileprivate var pointToParent = CGPoint(x: 0, y: 0)
    fileprivate var backgroundView = UIView()
    fileprivate var keyboardHeight: CGFloat = 0
    fileprivate var arrow: Arrow!
    fileprivate var table: UITableView!
    fileprivate var shadow: UIView!
    fileprivate var bubbleShape: Arrow!
    fileprivate var tablePosition: TablePosition!

    public var selectedIndex: Int?

    public var optionArray = [String]() {
        didSet {
            self.dataArray = self.optionArray
        }
    }

    public var optionImageArray = [String]() {
        didSet {
            self.imageArray = self.optionImageArray
        }
    }

    public var optionIds: [String]?
    var searchText = String() {
        didSet {
            if searchText == "" {
                self.dataArray = self.optionArray
            }
            else {
                self.dataArray = optionArray.filter {
                    $0.removeAccent().range(of: searchText.removeAccent(), options: .caseInsensitive) != nil
                }
            }
            reSizeTable()
            selectedIndex = nil
            self.table.reloadData()
        }
    }

    // MARK: KTO only
    var ktoOffset = CGRect.zero
    var ktoKeyboardToolbarHeight: CGFloat = 44
    var emptyTip = false
    // MARK: Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.delegate = self
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupUI()
        self.delegate = self
    }

    // MARK: Closures
    fileprivate var didSelectCompletion: (String, Int, String) -> Void = { _, _, _ in }
    fileprivate var TableWillAppearCompletion: () -> Void = { }
    fileprivate var TableDidAppearCompletion: () -> Void = { }
    fileprivate var TableWillDisappearCompletion: () -> Void = { }
    fileprivate var TableDidDisappearCompletion: () -> Void = { }

    func setupUI() {
        let size = self.frame.height
        let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
        self.rightView = rightView
        self.rightViewMode = .always
        let arrowContainerView = UIView(frame: rightView.frame)
        self.rightView?.addSubview(arrowContainerView)
        let center = arrowContainerView.center
        arrow = Arrow(origin: CGPoint(x: center.x - arrowSize / 2, y: center.y - arrowSize / 2), size: arrowSize)
        arrowContainerView.addSubview(arrow)

        self.backgroundView = UIView(frame: .zero)
        self.backgroundView.backgroundColor = .clear
        addGesture()
        if isSearchEnable, handleKeyboard {
            NotificationCenter.default
                .addObserver(
                    forName: UIResponder.keyboardDidShowNotification,
                    object: nil,
                    queue: nil)
            { [weak self] notification in
                guard let self else { return }
                if self.isFirstResponder {
                    let userInfo: NSDictionary = notification.userInfo! as NSDictionary
                    let keyboardFrame: NSValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    self.keyboardHeight = keyboardRectangle.height + (self.ktoKeyboardToolbarHeight * 0.6)
                    if self.isSelected {
                        self.reSizeTable()
                    }
                    else {
                        self.showList()
                    }
                }
            }
            NotificationCenter.default
                .addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] _ in
                    guard let self else { return }
                    if self.isFirstResponder {
                        self.keyboardHeight = 0
                    }
                }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func addGesture() {
        if !isSearchEnable, traverseSuperViewsIsScrollView(self) {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            self.addGestureRecognizer(gesture)
        }
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(touchBackground))
        self.backgroundView.addGestureRecognizer(gesture2)
    }

    private func traverseSuperViewsIsScrollView(_ view: UIView) -> Bool {
        var inputView: UIView? = view
        while inputView != nil {
            guard let view = inputView else { continue }
            inputView = view.superview
            if inputView is UIScrollView {
                return true
            }
        }
        return false
    }

    func getConvertedPoint(_ targetView: UIView, baseView: UIView?) -> CGPoint {
        var pnt = CGPoint(x: targetView.frame.origin.x - ktoOffset.origin.x, y: targetView.frame.origin.y - ktoOffset.origin.y)
        if targetView.superview == nil {
            return pnt
        }
        var superView = targetView.superview
        while superView != baseView {
            pnt = superView!.convert(pnt, to: superView!.superview)
            if superView!.superview == nil {
                break
            }
            else {
                superView = superView!.superview
            }
        }
        return superView!.convert(pnt, to: baseView)
    }

    private func displayNoReasultFooter() {
        let noResult = NoResultFooter()
        self.table.tableFooterView = noResult
    }

    public func showList() {
        guard !isSelected else { return }
        if parentController == nil {
            parentController = self.parentViewController
        }
        backgroundView.frame = parentController?.view.frame ?? backgroundView.frame
        pointToParent = getConvertedPoint(self, baseView: parentController?.view)
        parentController?.view.insertSubview(backgroundView, aboveSubview: self)
        TableWillAppearCompletion()
        if listHeight > rowHeight * CGFloat(dataArray.count) + TableHeaderHeight + TableFooterHeight {
            self.tableHeightX = rowHeight * CGFloat(dataArray.count) + TableHeaderHeight + TableFooterHeight
        }
        else {
            self.tableHeightX = listHeight
        }
        table = UITableView(frame: CGRect(
            x: pointToParent.x,
            y: pointToParent.y,
            width: self.frame.width + self.ktoOffset.origin.x,
            height: 0))
        shadow = UIView(frame: table.frame)
        shadow.backgroundColor = .clear

        table.dataSource = self
        table.delegate = self
        table.alpha = 0
        table.separatorStyle = .none
        table.layer.cornerRadius = 8
        table.backgroundColor = rowBackgroundColor
        table.rowHeight = rowHeight
        table.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: table.frame.size.width, height: TableHeaderHeight))
        table.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: table.frame.size.width, height: TableFooterHeight))
        parentController?.view.addSubview(shadow)
        parentController?.view.addSubview(table)
        self.isSelected = true
        let height = (self.parentController?.view.frame.height ?? 0) - (self.pointToParent.y + ktoOffset.size.height)
        var y: CGFloat
        var bubbleY: CGFloat
        bubbleShape = Arrow(origin: CGPoint.zero, width: 16, height: 8, solid: .filled)
        if height < (keyboardHeight + tableHeightX) {
            y = self.pointToParent.y - tableHeightX - BubbleSpace
            bubbleY = self.pointToParent.y - BubbleSpace
            bubbleShape.position = .down
            tablePosition = .above
        }
        else {
            y = self.pointToParent.y + ktoOffset.size.height + BubbleSpace
            bubbleY = y - BubbleSpace + 2
            bubbleShape.position = .up
            tablePosition = .under
        }
        bubbleShape.frame.origin = CGPoint(x: self.pointToParent.x + 20, y: bubbleY)
        bubbleShape.arrowColor = rowBackgroundColor
        bubbleShape.alpha = 0
        parentController?.view.addSubview(bubbleShape)
        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.1,
            options: .curveEaseInOut,
            animations: { [weak self] () in
                guard let self else { return }
                self.table.frame = CGRect(
                    x: self.pointToParent.x,
                    y: y,
                    width: self.frame.width + self.ktoOffset.origin.x,
                    height: self.tableHeightX)
                self.table.alpha = 1
                self.shadow.frame = self.table.frame
                self.shadow.dropShadow()
                self.arrow.position = .up
                self.bubbleShape.alpha = self.tableHeightX > 0 ? 1 : 0
            },
            completion: { [weak self] _ in
                self?.layoutIfNeeded()
            })
    }

    public func hideList() {
        guard isSelected else { return }
        TableWillDisappearCompletion()
        var y: CGFloat
        if tablePosition == .above {
            y = self.pointToParent.y - BubbleSpace
        }
        else {
            y = self.pointToParent.y + ktoOffset.size.height + BubbleSpace
        }
        UIView.animate(
            withDuration: 0.5,
            delay: 0.1,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.1,
            options: .curveEaseInOut,
            animations: { [weak self] () in
                guard let self else { return }
                self.table.frame = CGRect(
                    x: self.pointToParent.x,
                    y: y,
                    width: self.frame.width + self.ktoOffset.origin.x,
                    height: 0)
                self.bubbleShape.alpha = 0
                self.shadow.alpha = 0
                self.shadow.frame = self.table.frame
                self.arrow.position = .down
            },
            completion: { [weak self] _ in
                self?.bubbleShape.removeFromSuperview()
                self?.shadow.removeFromSuperview()
                self?.table.tableFooterView = nil
                self?.table.removeFromSuperview()
                self?.backgroundView.removeFromSuperview()
                self?.isSelected = false
                self?.TableDidDisappearCompletion()
            })
    }

    @objc
    private func touchBackground() {
        superview?.endEditing(true)
        touchAction()
    }

    @objc
    public func touchAction() {
        isSelected ? hideList() : showList()
    }

    @objc
    func tapAction() {
        self.didDropDownTap?()
    }

    func reSizeTable() {
        if emptyTip, dataArray.count == 0 {
            self.tableHeightX = NoResultFooter.footerHeight
            self.displayNoReasultFooter()
        }
        else if listHeight > rowHeight * CGFloat(dataArray.count) + TableHeaderHeight + TableFooterHeight {
            self.tableHeightX = rowHeight * CGFloat(dataArray.count) + TableHeaderHeight + TableFooterHeight
        }
        else {
            self.tableHeightX = listHeight
        }
        let height = (self.parentController?.view.frame.height ?? 0) - (self.pointToParent.y + ktoOffset.size.height)
        var y: CGFloat
        var bubbleY: CGFloat
        var bubbleDirection: Position
        if height < (keyboardHeight + tableHeightX) {
            y = self.pointToParent.y - tableHeightX - BubbleSpace
            tablePosition = .above
            bubbleY = self.pointToParent.y - BubbleSpace
            bubbleDirection = .down
        }
        else {
            y = self.pointToParent.y + ktoOffset.size.height + BubbleSpace
            tablePosition = .under
            bubbleY = y - BubbleSpace + 2
            bubbleDirection = .up
        }

        UIView.animate(
            withDuration: 0.2,
            delay: 0.1,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.1,
            options: .curveEaseInOut,
            animations: { [weak self] () in
                guard let self else { return }
                self.table.frame = CGRect(
                    x: self.pointToParent.x,
                    y: y,
                    width: self.frame.width + self.ktoOffset.origin.x,
                    height: self.tableHeightX)
                self.shadow.frame = self.table.frame
                self.shadow.dropShadow()
                self.bubbleShape.alpha = self.tableHeightX > 0 ? 1 : 0
                self.bubbleShape.position = bubbleDirection
                self.bubbleShape.frame.origin = CGPoint(x: self.pointToParent.x + 20, y: bubbleY)
            },
            completion: { [weak self] _ in
                self?.layoutIfNeeded()
            })
    }

    // MARK: Actions Methods
    public var didDropDownTap: (() -> Void)?

    public func didSelect(completion: @escaping (_ selectedText: String, _ index: Int, _ id: String) -> Void) {
        didSelectCompletion = completion
    }

    public func listWillAppear(completion: @escaping () -> Void) {
        TableWillAppearCompletion = completion
    }

    public func listDidAppear(completion: @escaping () -> Void) {
        TableDidAppearCompletion = completion
    }

    public func listWillDisappear(completion: @escaping () -> Void) {
        TableWillDisappearCompletion = completion
    }

    public func listDidDisappear(completion: @escaping () -> Void) {
        TableDidDisappearCompletion = completion
    }
}

extension DropDown {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        next?.touchesBegan(touches, with: event)
    }
}

// MARK: UITextFieldDelegate
extension DropDown: UITextFieldDelegate {
    public func textFieldShouldReturn(_: UITextField) -> Bool {
        superview?.endEditing(true)
        if isSelected {
            hideList()
        }
        return false
    }

    public func textFieldDidBeginEditing(_: UITextField) {
        self.dataArray = self.optionArray
        touchAction()
    }

    public func textFieldShouldBeginEditing(_: UITextField) -> Bool {
        isSearchEnable
    }

    public func textField(_: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let subText = self.text as NSString? {
            self.searchText = subText.replacingCharacters(in: range, with: string)
        }
        if !isSelected {
            showList()
        }
        return true
    }
}

// MARK: UITableViewDataSource
extension DropDown: UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "DropDownCell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        if indexPath.row != selectedIndex {
            cell!.backgroundColor = rowBackgroundColor
        }
        else {
            cell?.backgroundColor = selectedRowColor
        }

        if self.imageArray.count > indexPath.row {
            cell!.imageView!.image = UIImage(named: imageArray[indexPath.row])
        }
        cell!.textLabel!.text = "\(dataArray[indexPath.row])"
        cell!.textLabel?.textColor = rowTextColor
        cell!.accessoryType = (indexPath.row == selectedIndex) && checkMarkEnabled ? .checkmark : .none
        cell!.selectionStyle = .none
        cell?.textLabel?.font = self.font
        cell?.textLabel?.textAlignment = self.textAlignment
        cell?.textLabel?.numberOfLines = 0
        cell?.textLabel?.lineBreakMode = .byWordWrapping
        return cell!
    }
}

// MARK: UITableViewDelegate
extension DropDown: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = (indexPath as NSIndexPath).row
        let selectedText = self.dataArray[self.selectedIndex!]
        tableView.cellForRow(at: indexPath)?.alpha = 0
        UIView.animate(
            withDuration: 0.5,
            animations: { () in
                tableView.cellForRow(at: indexPath)?.alpha = 1.0
                tableView.cellForRow(at: indexPath)?.backgroundColor = self.selectedRowColor
            },
            completion: { [weak self] _ in
                self?.text = "\(selectedText)"
                tableView.reloadData()
            })
        if hideOptionsWhenSelect {
            touchAction()
            self.endEditing(true)
        }
        if let selected = optionArray.firstIndex(where: { $0 == selectedText }) {
            if let id = optionIds?[selected] {
                didSelectCompletion(selectedText, selected, id)
            }
            else {
                didSelectCompletion(selectedText, selected, "")
            }
        }
    }
}

// MARK: Arrow
enum Position {
    case left
    case down
    case right
    case up
}

enum Solid {
    case filled
    case linear
    case filledWithCorner
}

class Arrow: UIView {
    let shapeLayer = CAShapeLayer()
    var arrowColor: UIColor = .black {
        didSet {
            shapeLayer.strokeColor = arrowColor.cgColor
        }
    }

    var position: Position = .down {
        didSet {
            switch position {
            case .left:
                self.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
            case .down:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2)
            case .right:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            case .up:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }
        }
    }

    var solid: Solid {
        didSet {
            self.setNeedsLayout()
        }
    }

    init(origin: CGPoint, size: CGFloat, solid: Solid = .linear) {
        self.solid = solid
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: size, height: size))
    }

    init(origin: CGPoint, width: CGFloat, height: CGFloat, solid: Solid = .linear) {
        self.solid = solid
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: width, height: height))
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_: CGRect) {
        switch solid {
        case .filled:
            shapeLayer.path = drawnFilledTriangle()
        case .linear:
            shapeLayer.path = drawLinearPath()
        case .filledWithCorner:
            shapeLayer.path = drawnFilledTriangleWithCorner()
        }

        shapeLayer.fillColor = arrowColor.cgColor

        if #available(iOS 12.0, *) {
            self.layer.addSublayer(shapeLayer)
        }
        else {
            self.layer.mask = shapeLayer
        }
    }

    private func drawLinearPath() -> CGPath {
        let bezierPath = UIBezierPath()
        let size = self.layer.frame.width
        let qSize = size / 4
        bezierPath.move(to: CGPoint(x: size, y: qSize))
        bezierPath.addLine(to: CGPoint(x: size / 2, y: qSize * 3))
        bezierPath.move(to: CGPoint(x: size / 2, y: qSize * 3))
        bezierPath.addLine(to: CGPoint(x: 0, y: qSize))
        bezierPath.close()
        return bezierPath.cgPath
    }

    private func drawnFilledTriangleWithCorner() -> CGPath {
        let size = self.layer.frame.width
        let qSize = size / 4
        let radius = qSize / 4

        let point1 = CGPoint(x: size, y: qSize)
        let point2 = CGPoint(x: size / 2, y: qSize * 3)
        let point3 = CGPoint(x: 0, y: qSize)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size / 2, y: qSize))
        path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
        path.addArc(tangent1End: point2, tangent2End: point3, radius: radius)
        path.addArc(tangent1End: point3, tangent2End: point1, radius: radius)
        path.closeSubpath()
        return path
    }

    private func drawnFilledTriangle() -> CGPath {
        let bezierPath = UIBezierPath()
        let width = self.layer.frame.width
        let height = self.layer.frame.height
        bezierPath.move(to: CGPoint(x: 0, y: 0))
        bezierPath.addLine(to: CGPoint(x: width, y: 0))
        bezierPath.addLine(to: CGPoint(x: width / 2, y: height))
        bezierPath.move(to: CGPoint(x: width / 2, y: height))
        bezierPath.addLine(to: CGPoint(x: width, y: 0))
        bezierPath.close()
        return bezierPath.cgPath
    }
}

class NoResultFooter: UIControl {
    static let footerHeight: CGFloat = 72.0
    var message: String? {
        didSet {
            self.label.text = message
        }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.greyScaleToast
        label.textColor = UIColor.textSecondary
        label.font = UIFont(name: "PingFangSC-Regular", size: 16)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setDefault()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setDefault()
    }

    convenience init() {
        self.init(frame: CGRect(
            x: .zero,
            y: .zero,
            width: UIScreen.main.bounds.size.width,
            height: Self.footerHeight))
    }

    private func setupUI() {
        self.addSubview(label, constraints: .fill())
    }

    private func setDefault() {
        self.backgroundColor = UIColor.white
        self.message = Localize.string("common_empty_data")
    }
}
