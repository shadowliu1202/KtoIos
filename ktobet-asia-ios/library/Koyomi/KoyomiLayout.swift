import UIKit

final class KoyomiLayout: UICollectionViewLayout {
  // Internal properties
  let inset: UIEdgeInsets
  let cellSpace: CGFloat
  let sectionSpace: CGFloat
  let weekCellHeight: CGFloat

  // Fileprivate properties
  fileprivate var layoutAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

  // MARK: - Initializer -

  init(inset: UIEdgeInsets, cellSpace: CGFloat, sectionSpace: CGFloat, weekCellHeight: CGFloat) {
    self.inset = inset
    self.cellSpace = cellSpace
    self.sectionSpace = sectionSpace
    self.weekCellHeight = weekCellHeight
    super.init()
  }

  required init?(coder _: NSCoder) {
    fatalError("Please use custom initialization")
  }
}

// MARK: - Override Methods -

extension KoyomiLayout {
  override func prepare() {
    let sectionCount = collectionView?.numberOfSections ?? 0
    (0..<sectionCount).forEach { section in
      let itemCount = collectionView?.numberOfItems(inSection: section) ?? 0
      (0..<itemCount).forEach { row in
        let indexPath: IndexPath = .init(row: row, section: section)
        let attribute: UICollectionViewLayoutAttributes = .init(forCellWith: indexPath)
        attribute.frame = frame(at: indexPath)
        layoutAttributes[indexPath] = attribute
      }
    }
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    layoutAttributes.filter { rect.contains($0.1.frame) }.map { $0.1 }
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    layoutAttributes[indexPath]
  }

  override var collectionViewContentSize: CGSize {
    collectionView?.frame.size ?? .zero
  }
}

// MARK: - Private Methods -

extension KoyomiLayout {
  fileprivate struct Constant {
    static let maxLineSpaceCount = 5
    static let maxRowCount = 6
    static var columnCount: CGFloat {
      CGFloat(DateModel.dayCountPerRow)
    }
  }

  private var width: CGFloat { collectionView?.frame.width ?? 0 }
  private var height: CGFloat { collectionView?.frame.height ?? 0 }

  private func frame(at indexPath: IndexPath) -> CGRect {
    let isWeekCell = indexPath.section == 0

    let availableWidth = width - (cellSpace * CGFloat(Constant.columnCount - 1) + inset.right + inset.left)
    let availableHeight = height -
      (cellSpace * CGFloat(Constant.maxLineSpaceCount) + inset.bottom + inset.top + sectionSpace + weekCellHeight)

    var cellWidth = availableWidth / Constant.columnCount
    let cellHeight = isWeekCell ? weekCellHeight : availableHeight / CGFloat(Constant.maxRowCount)

    let row = floor(CGFloat(indexPath.row) / Constant.columnCount)
    let column = CGFloat(indexPath.row) - row * Constant.columnCount

    let lineSpace = row == 0 ? 0 : cellSpace
    let y = isWeekCell ? inset.top : row * (cellHeight + lineSpace) + weekCellHeight + sectionSpace + inset.top
    let x = (cellWidth + cellSpace) * column + inset.left

    // For disappearing cell under specific width
    if x + cellWidth > width, indexPath.row % 7 == 6 {
      cellWidth = width - x
    }

    return CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
  }
}
