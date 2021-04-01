
//
//  iOSDropDown.swift
//
//
//  Created by Jishnu Raj T on 26/04/18.
//  Copyright © 2018 JRiOSdev. All rights reserved.
//
import UIKit

open class DropDown : UITextField{
    //MARK: IBInspectable
    @IBInspectable public var rowHeight: CGFloat = 30
    @IBInspectable public var rowBackgroundColor: UIColor = .white
    @IBInspectable public var rowTextColor: UIColor = .black
    @IBInspectable public var selectedRowColor: UIColor = .cyan
    @IBInspectable public var hideOptionsWhenSelect = true
    @IBInspectable public var isSearchEnable: Bool = true {
        didSet{
            addGesture()
        }
    }
    @IBInspectable public var borderColor: UIColor =  UIColor.lightGray {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    @IBInspectable public var listHeight: CGFloat = 150{
        didSet {

        }
    }
    @IBInspectable public var arrowSize: CGFloat = 15 {
        didSet{
            let center =  arrow.superview!.center
            arrow.frame = CGRect(x: center.x - arrowSize/2, y: center.y - arrowSize/2, width: arrowSize, height: arrowSize)
        }
    }
    @IBInspectable public var arrowColor: UIColor = .black {
        didSet{
            arrow.arrowColor = arrowColor
        }
    }
    @IBInspectable public var checkMarkEnabled: Bool = true {
        didSet{
            
        }
    }
    @IBInspectable public var handleKeyboard: Bool = true {
        didSet{
            
        }
    }

    //MARK: Variables
    fileprivate var tableheightX: CGFloat = 100
    fileprivate var dataArray = [String]()
    fileprivate var imageArray = [String]()
    fileprivate weak var parentController:UIViewController?
    fileprivate var pointToParent = CGPoint(x: 0, y: 0)
    fileprivate var backgroundView = UIView()
    fileprivate var keyboardHeight:CGFloat = 0
    fileprivate var arrow : Arrow!
    fileprivate var table : UITableView!
    fileprivate var shadow : UIView!
    
    public var selectedIndex: Int?
    
    public var optionArray = [String]() {
        didSet{
            self.dataArray = self.optionArray
        }
    }
    public var optionImageArray = [String]() {
        didSet{
            self.imageArray = self.optionImageArray
        }
    }
    public var optionIds : [Int]?
    var searchText = String() {
        didSet{
            if searchText == "" {
                self.dataArray = self.optionArray
            }else{
                self.dataArray = optionArray.filter {
                    return $0.range(of: searchText, options: .caseInsensitive) != nil
                }
            }
            reSizeTable()
            selectedIndex = nil
            self.table.reloadData()
        }
    }
    
    //MARK: KTO only
    var ktoOffset = CGRect.zero
    //MARK: Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.delegate = self
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupUI()
        self.delegate = self
    }

    //MARK: Closures
    fileprivate var didSelectCompletion: (String, Int ,Int) -> () = {selectedText, index , id  in }
    fileprivate var TableWillAppearCompletion: () -> () = { }
    fileprivate var TableDidAppearCompletion: () -> () = { }
    fileprivate var TableWillDisappearCompletion: () -> () = { }
    fileprivate var TableDidDisappearCompletion: () -> () = { }

    func setupUI () {
        let size = self.frame.height
        let rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
        self.rightView = rightView
        self.rightViewMode = .always
        let arrowContainerView = UIView(frame: rightView.frame)
        self.rightView?.addSubview(arrowContainerView)
        let center = arrowContainerView.center
        arrow = Arrow(origin: CGPoint(x: center.x - arrowSize/2,y: center.y - arrowSize/2),size: arrowSize)
        arrowContainerView.addSubview(arrow)

        self.backgroundView = UIView(frame: .zero)
        self.backgroundView.backgroundColor = .clear
        addGesture()
        if isSearchEnable && handleKeyboard{
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] (notification) in
                guard let `self` = self else {return}
                if self.isFirstResponder{
                let userInfo:NSDictionary = notification.userInfo! as NSDictionary
                    let keyboardFrame:NSValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                let keyboardRectangle = keyboardFrame.cgRectValue
                self.keyboardHeight = keyboardRectangle.height
                    if self.isSelected{
                        self.reSizeTable()
                    } else {
                        self.showList()
                    }
                }
              
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] (notification) in
                guard let `self` = self else {return}
                if self.isFirstResponder{
                self.keyboardHeight = 0
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addGesture (){
        if !isSearchEnable && traverseSuperViewsIsScrollView(self) {
            let gesture =  UITapGestureRecognizer(target: self, action:  #selector(tapAction))
            self.addGestureRecognizer(gesture)
        }
        let gesture2 =  UITapGestureRecognizer(target: self, action:  #selector(touchBackground))
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
    
    func getConvertedPoint(_ targetView: UIView, baseView: UIView?)->CGPoint{
        var pnt = CGPoint(x: targetView.frame.origin.x - ktoOffset.origin.x, y: targetView.frame.origin.y - ktoOffset.origin.y)
        if nil == targetView.superview{
            return pnt
        }
        var superView = targetView.superview
        while superView != baseView{
            pnt = superView!.convert(pnt, to: superView!.superview)
            if nil == superView!.superview{
                break
            }else{
                superView = superView!.superview
            }
        }
        return superView!.convert(pnt, to: baseView)
    }
    public func showList() {
        guard !isSelected else { return }
        if parentController == nil{
            parentController = self.parentViewController
        }
        backgroundView.frame = parentController?.view.frame ?? backgroundView.frame
        pointToParent = getConvertedPoint(self, baseView: parentController?.view)
        parentController?.view.insertSubview(backgroundView, aboveSubview: self)
        TableWillAppearCompletion()
        if listHeight > rowHeight * CGFloat( dataArray.count) {
            self.tableheightX = rowHeight * CGFloat(dataArray.count)
        }else{
            self.tableheightX = listHeight
        }
        table = UITableView(frame: CGRect(x: pointToParent.x,
                                          y: pointToParent.y,
                                          width: self.frame.width + self.ktoOffset.size.width,
                                          height: self.frame.height))
        shadow = UIView(frame: table.frame)
        shadow.backgroundColor = .clear

        table.dataSource = self
        table.delegate = self
        table.alpha = 0
        table.separatorStyle = .none
        table.layer.cornerRadius = 3
        table.backgroundColor = rowBackgroundColor
        table.rowHeight = rowHeight
        parentController?.view.addSubview(shadow)
        parentController?.view.addSubview(table)
        self.isSelected = true
        let height = (self.parentController?.view.frame.height ?? 0) - (self.pointToParent.y + self.frame.height + 5)
        var y = self.pointToParent.y+self.frame.height+5
        if height < (keyboardHeight+tableheightX){
            y = self.pointToParent.y - tableheightX
        } else {
            y += ktoOffset.origin.y
        }
        UIView.animate(withDuration: 0.5,
                       delay: 0.1,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in

                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: y,
                                                  width: self.frame.width + self.ktoOffset.size.width,
                                                  height: self.tableheightX)
                        self.table.alpha = 1
                        self.shadow.frame = self.table.frame
                        self.shadow.dropShadow()
                        self.arrow.position = .up
                       

        },
                       completion: { (finish) -> Void in
                        self.layoutIfNeeded()

        })

    }


    public func hideList() {
        guard isSelected else { return }
        TableWillDisappearCompletion()
        UIView.animate(withDuration: 0.5,
                       delay: 0.1,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in
                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: self.pointToParent.y+self.frame.height-self.ktoOffset.origin.y,
                                                  width: self.frame.width + self.ktoOffset.size.width,
                                                  height: 0)
                        self.shadow.alpha = 0
                        self.shadow.frame = self.table.frame
                        self.arrow.position = .down
        },
                       completion: { (didFinish) -> Void in

                        self.shadow.removeFromSuperview()
                        self.table.removeFromSuperview()
                        self.backgroundView.removeFromSuperview()
                        self.isSelected = false
                        self.TableDidDisappearCompletion()
        })
    }

    @objc private func touchBackground() {
        superview?.endEditing(true)
        touchAction()
    }
    
    @objc public func touchAction() {
        isSelected ?  hideList() : showList()
    }
    
    @objc func tapAction() {
        self.didDropDownTap?()
    }
    
    func reSizeTable() {
        if listHeight > rowHeight * CGFloat( dataArray.count) {
            self.tableheightX = rowHeight * CGFloat(dataArray.count)
        }else{
            self.tableheightX = listHeight
        }
        let height = (self.parentController?.view.frame.height ?? 0) - (self.pointToParent.y + self.frame.height + 5)
        var y = self.pointToParent.y+self.frame.height+5
        if height < (keyboardHeight+tableheightX){
            y = self.pointToParent.y - tableheightX
        } else {
            y += ktoOffset.origin.y
        }
        UIView.animate(withDuration: 0.2,
                       delay: 0.1,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: { () -> Void in
                        self.table.frame = CGRect(x: self.pointToParent.x,
                                                  y: y,
                                                  width: self.frame.width + self.ktoOffset.size.width,
                                                  height: self.tableheightX)
                        self.shadow.frame = self.table.frame
                        self.shadow.dropShadow()

        },
                       completion: { (didFinish) -> Void in
                      //  self.shadow.layer.shadowPath = UIBezierPath(rect: self.table.bounds).cgPath
                        self.layoutIfNeeded()

        })
    }

    //MARK: Actions Methods
    public var didDropDownTap: (() -> ())?
    
    public func didSelect(completion: @escaping (_ selectedText: String, _ index: Int , _ id:Int ) -> ()) {
        didSelectCompletion = completion
    }

    public func listWillAppear(completion: @escaping () -> ()) {
        TableWillAppearCompletion = completion
    }

    public func listDidAppear(completion: @escaping () -> ()) {
        TableDidAppearCompletion = completion
    }

    public func listWillDisappear(completion: @escaping () -> ()) {
        TableWillDisappearCompletion = completion
    }

    public func listDidDisappear(completion: @escaping () -> ()) {
        TableDidDisappearCompletion = completion
    }

}

extension DropDown {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        next?.touchesBegan(touches, with: event)
    }
}

//MARK: UITextFieldDelegate
extension DropDown : UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        superview?.endEditing(true)
        if isSelected {
            hideList()
        }
        return false
    }
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.dataArray = self.optionArray
        touchAction()
    }
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return isSearchEnable
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isContainsPhoneticCharacters() {
            return true
        }
        if let subText = self.text as NSString? {
            self.searchText = subText.replacingCharacters(in: range, with: string)
        }
        if !isSelected {
            showList()
        }
        return true
    }

}
///MARK: UITableViewDataSource
extension DropDown: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "DropDownCell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)

        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        if indexPath.row != selectedIndex{
            cell!.backgroundColor = rowBackgroundColor
        }else {
            cell?.backgroundColor = selectedRowColor
        }

        if self.imageArray.count > indexPath.row {
            cell!.imageView!.image = UIImage(named: imageArray[indexPath.row])
        }
        cell!.textLabel!.text = "\(dataArray[indexPath.row])"
        cell!.textLabel?.textColor = rowTextColor
        cell!.accessoryType = (indexPath.row == selectedIndex) && checkMarkEnabled  ? .checkmark : .none
        cell!.selectionStyle = .none
        cell?.textLabel?.font = self.font
        cell?.textLabel?.textAlignment = self.textAlignment
        cell?.textLabel?.numberOfLines = 0
        cell?.textLabel?.lineBreakMode = .byWordWrapping
        return cell!
    }
}
//MARK: UITableViewDelegate
extension DropDown: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = (indexPath as NSIndexPath).row
        let selectedText = self.dataArray[self.selectedIndex!]
        tableView.cellForRow(at: indexPath)?.alpha = 0
        UIView.animate(withDuration: 0.5,
                       animations: { () -> Void in
                        tableView.cellForRow(at: indexPath)?.alpha = 1.0
                        tableView.cellForRow(at: indexPath)?.backgroundColor = self.selectedRowColor
        } ,
                       completion: { (didFinish) -> Void in
                        self.text = "\(selectedText)"

                        tableView.reloadData()
        })
        if hideOptionsWhenSelect {
            touchAction()
            self.endEditing(true)
        }
        if let selected = optionArray.firstIndex(where: {$0 == selectedText}) {
            if let id = optionIds?[selected] {
                didSelectCompletion(selectedText, selected , id )
            }else{
                didSelectCompletion(selectedText, selected , 0)
            }

        }

    }
}

//MARK: Arrow
enum Position {
    case left
    case down
    case right
    case up
}

class Arrow: UIView {
    let shapeLayer = CAShapeLayer()
    var arrowColor:UIColor = .black {
        didSet{
            shapeLayer.strokeColor = arrowColor.cgColor
        }
    }
    
    var position: Position = .down {
        didSet{
            switch position {
            case .left:
                self.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
                break

            case .down:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi*2)
                break

            case .right:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
                break

            case .up:
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                break
            }
        }
    }

    init(origin: CGPoint, size: CGFloat ) {
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: size, height: size))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {

        // Get size
        let size = self.layer.frame.width

        // Create path
        let bezierPath = UIBezierPath()

        // Draw points
        let qSize = size/4

        bezierPath.move(to: CGPoint(x: size, y: qSize))
        bezierPath.addLine(to: CGPoint(x: size/2, y: qSize*3))
        bezierPath.move(to: CGPoint(x: size/2, y: qSize*3))
        bezierPath.addLine(to: CGPoint(x: 0, y: qSize))
        bezierPath.close()

        // Mask to path
        shapeLayer.path = bezierPath.cgPath
       
        if #available(iOS 12.0, *) {
            self.layer.addSublayer (shapeLayer)
        } else {
            self.layer.mask = shapeLayer
        }
    }
}

extension UIView {

    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 2
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func viewBorder(borderColor : UIColor, borderWidth : CGFloat?) {
        self.layer.borderColor = borderColor.cgColor
        if let borderWidth_ = borderWidth {
            self.layer.borderWidth = borderWidth_
        } else {
            self.layer.borderWidth = 1.0
        }
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}


