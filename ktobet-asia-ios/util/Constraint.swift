import UIKit

public struct Constraint {
  public enum Kind {
    case equal
    case greaterThanOrEqual
    case lessThanOrEqual
  }

  let build: (_ child: UIView, _ parent: UIView) -> NSLayoutConstraint

  public init(build: @escaping (_ child: UIView, _ parent: UIView) -> NSLayoutConstraint) {
    self.build = build
  }

  public func set<Value>(_ keyPath: ReferenceWritableKeyPath<NSLayoutConstraint, Value>, value: Value) -> Constraint {
    Constraint { view, parent in
      let constraint = self.build(view, parent)
      constraint[keyPath: keyPath] = value
      return constraint
    }
  }
}

// MARK: - Constraint Builder Helper
extension Constraint {
  public static func constraint<Axis>(
    _ kind: Kind,
    _ to: KeyPath<UIView, some NSLayoutAnchor<Axis>>,
    offset: CGFloat = 0,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    constraint(kind, from: to, to: to, offset: offset, priority: priority)
  }

  public static func constraint<L, Axis>(
    _ kind: Kind,
    from fromKeyPath: KeyPath<UIView, L>,
    to toKeyPath: KeyPath<UIView, L>,
    offset: CGFloat = 0,
    priority: UILayoutPriority = .required) -> Constraint
    where L: NSLayoutAnchor<Axis>
  {
    Constraint { view, parent in
      let constraint: NSLayoutConstraint = {
        switch kind {
        case .equal:
          return view[keyPath: fromKeyPath].constraint(
            equalTo: parent[keyPath: toKeyPath],
            constant: offset)
        case .greaterThanOrEqual:
          return view[keyPath: fromKeyPath].constraint(
            greaterThanOrEqualTo: parent[keyPath: toKeyPath],
            constant: offset)
        case .lessThanOrEqual:
          return view[keyPath: fromKeyPath].constraint(
            lessThanOrEqualTo: parent[keyPath: toKeyPath],
            constant: offset)
        }
      }()
      constraint.priority = priority
      return constraint
    }
  }

  public static func constraint(
    _ kind: Kind,
    _ keyPath: KeyPath<UIView, some NSLayoutDimension>,
    length: CGFloat,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    Constraint { view, _ in
      let constraint: NSLayoutConstraint = {
        switch kind {
        case .equal:
          return view[keyPath: keyPath].constraint(
            equalToConstant: length)
        case .greaterThanOrEqual:
          return view[keyPath: keyPath].constraint(
            greaterThanOrEqualToConstant: length)
        case .lessThanOrEqual:
          return view[keyPath: keyPath].constraint(
            lessThanOrEqualToConstant: length)
        }
      }()
      constraint.priority = priority
      return constraint
    }
  }

  // MARK: - Equal Constraint
  public static func equal<Axis>(
    _ to: KeyPath<UIView, some NSLayoutAnchor<Axis>>,
    offset: CGFloat = 0,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    equal(to, to, offset: offset, priority: priority)
  }

  public static func equal(
    _ keyPath: KeyPath<UIView, some NSLayoutDimension>,
    length: CGFloat,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    Constraint { view, _ in
      let constraint = view[keyPath: keyPath].constraint(
        equalToConstant: length)
      constraint.priority = priority
      return constraint
    }
  }

  public static func equal<L, Axis>(
    _ from: KeyPath<UIView, L>,
    _ to: KeyPath<UIView, L>,
    offset: CGFloat = 0,
    priority: UILayoutPriority = .required) -> Constraint
    where L: NSLayoutAnchor<Axis>
  {
    Constraint { view, parent in
      let constraint = view[keyPath: from].constraint(
        equalTo: parent[keyPath: to],
        constant: offset)
      constraint.priority = priority
      return constraint
    }
  }

  // MARK: -
  public static func const(_ constraint: NSLayoutConstraint) -> Constraint {
    Constraint { _, _ in constraint }
  }

  public static func ratio(_ size: CGSize, priority: UILayoutPriority = .required) -> Constraint {
    Constraint { view, _ in
      let constraint = view.widthAnchor.constraint(
        equalTo: view.heightAnchor,
        multiplier: size.width / size.height)
      constraint.priority = priority
      return constraint
    }
  }

  public static func ratioWidth(
    _ multiplier: CGFloat,
    equalTo: NSLayoutDimension,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    Constraint { view, _ in
      let constraint = view.widthAnchor.constraint(
        equalTo: equalTo,
        multiplier: multiplier)
      constraint.priority = priority
      return constraint
    }
  }

  public static func ratioHeight(
    _ multiplier: CGFloat,
    equalTo: NSLayoutDimension,
    priority: UILayoutPriority = .required)
    -> Constraint
  {
    Constraint { view, _ in
      let constraint = view.heightAnchor.constraint(
        equalTo: equalTo,
        multiplier: multiplier)
      constraint.priority = priority
      return constraint
    }
  }
}

// MARK: - UIView helper For adding constrints
extension UIView {
  public func addSubViewOnSafeAreaGuide(_ view: UIView) {
    self.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    let safeLayoutGuide = self.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: safeLayoutGuide.topAnchor),
      view.leadingAnchor.constraint(equalTo: safeLayoutGuide.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: safeLayoutGuide.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: safeLayoutGuide.bottomAnchor)
    ])
  }

  public func clearConstraints() {
    self.constraints.forEach { self.removeConstraint($0) }
  }

  @discardableResult
  public func addSubview(_ child: UIView, constraints: [Constraint]) -> [NSLayoutConstraint] {
    child.translatesAutoresizingMaskIntoConstraints = false
    addSubview(child)
    let result = constraints.map { $0.build(child, self) }
    NSLayoutConstraint.activate(result)
    return result
  }

  @discardableResult
  public func constrain(to view: UIView, constraints: [Constraint]) -> [NSLayoutConstraint] {
    translatesAutoresizingMaskIntoConstraints = false
    let result = constraints.map { $0.build(self, view) }
    NSLayoutConstraint.activate(result)
    return result
  }

  @discardableResult
  public func constrain(_ constraints: [Constraint]) -> [NSLayoutConstraint] {
    translatesAutoresizingMaskIntoConstraints = false
    let result = constraints.map { $0.build(self, self) }
    NSLayoutConstraint.activate(result)
    return result
  }
}

// MARK: - some default constraints, UILayoutPriority = .required
extension [Constraint] {
  public static var center: [Constraint] {
    [.equal(\.centerXAnchor), .equal(\.centerYAnchor)]
  }

  public static func inside(margin: UIEdgeInsets = .zero) -> [Constraint] {
    [
      .constraint(.greaterThanOrEqual, \.topAnchor, offset: margin.top),
      .constraint(.greaterThanOrEqual, \.leadingAnchor, offset: margin.left),
      .constraint(.lessThanOrEqual, \.trailingAnchor, offset: -margin.right),
      .constraint(.lessThanOrEqual, \.bottomAnchor, offset: -margin.bottom),
    ]
  }

  public static func insideCenter(margin: UIEdgeInsets = .zero) -> [Constraint] {
    .center + .inside(margin: margin)
  }

  public static func fill(margin: UIEdgeInsets = .zero) -> [Constraint] {
    fillWidth(marginLeft: margin.left, marginRight: margin.right) +
      fillHeight(marginTop: margin.top, marginBottom: margin.bottom)
  }

  public static func fillWidth(marginLeft: CGFloat = 0, marginRight: CGFloat = 0) -> [Constraint] {
    [
      .equal(\.leadingAnchor, offset: marginLeft),
      .equal(\.trailingAnchor, offset: -marginRight),
    ]
  }

  public static func fillWidth(margin: CGFloat) -> [Constraint] {
    fillWidth(marginLeft: margin, marginRight: margin)
  }

  public static func fillHeight(marginTop: CGFloat = 0, marginBottom: CGFloat = 0) -> [Constraint] {
    [
      .equal(\.topAnchor, offset: marginTop),
      .equal(\.bottomAnchor, offset: -marginBottom)
    ]
  }

  public static func fillHeight(margin: CGFloat) -> [Constraint] {
    fillHeight(marginTop: margin, marginBottom: margin)
  }

  // MARK: Size Constraints
  public static func size(_ size: CGSize) -> [Constraint] {
    [
      .equal(\.widthAnchor, length: size.width),
      .equal(\.heightAnchor, length: size.height),
    ]
  }

  public static func minimumsize(_ size: CGSize) -> [Constraint] {
    [
      .constraint(.greaterThanOrEqual, \.widthAnchor, length: size.width),
      .constraint(.greaterThanOrEqual, \.heightAnchor, length: size.height)
    ]
  }

  public static func maximumsize(_ size: CGSize) -> [Constraint] {
    [
      .constraint(.lessThanOrEqual, \.widthAnchor, length: size.width),
      .constraint(.lessThanOrEqual, \.heightAnchor, length: size.height)
    ]
  }
}

extension UIView {
  public func filterConstraint(attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
    self.constraints.filter {
      $0.firstAttribute == attribute
    }.first
  }
}
