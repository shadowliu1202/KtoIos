import SwiftUI

struct PromotionDropDownFilter<ViewModel>: View
  where ViewModel: CouponFilterable
{
  @State private var isExpand = false
  
  @StateObject private var viewModel: ViewModel
  
  private let productFilters: [PromotionFilter.Product] = [
    .Sport,
    .Slot,
    .Casino,
    .Numbergame,
    .Arcade
  ]
  
  private let onExpandStateChange: ((_ isExpand: Bool) -> Void)?
  
  init(
    viewModel: ViewModel,
    onExpandStateChange: ((_ isExpand: Bool) -> Void)? = nil)
  {
    self._viewModel = .init(wrappedValue: viewModel)
    self.onExpandStateChange = onExpandStateChange
  }
  
  var body: some View {
    header()
      .alignmentGuide(.top) { viewDimensions in
        viewDimensions[.top] + viewDimensions.height
      }
      .overlay(
        filterList()
          .visibility(
            isExpand
              ? .visible
              : .gone),
        alignment: .top)
      .onChange(of: isExpand) { newValue in
        onExpandStateChange?(newValue)
      }
  }
  
  // MARK: - Header
  
  @ViewBuilder
  private func header() -> some View {
    let selectedPromotionTag = viewModel.promotionTags
      .first(where: { $0.filter == viewModel.selectedPromotionFilter })
    
    VStack(spacing: 16) {
      Separator(color: .textSecondary, lineWeight: 0.5)
      
      HStack(spacing: 4) {
        Text(selectedPromotionTag?.name ?? "")
          .localized(
            weight: .medium,
            size: 12,
            color: isExpand
              ? .complementaryDefault
              : .textPrimary)
        
        Image(
          isExpand
            ? "promotionArrowDropUp"
            : "promotionArrowDropDown")
      }
      .padding(.horizontal, 30)
      .frame(maxWidth: .infinity, alignment: .leading)
      
      Separator(color: .textSecondary, lineWeight: 0.5)
    }
    .backgroundColor(.greyScaleList)
    .onTapGesture {
      isExpand.toggle()
    }
  }
  
  // MARK: - FilterList
  
  private func filterList() -> some View {
    ZStack(alignment: .top) {
      Color.clear
        .frame(height: UIScreen.main.bounds.height)
        .contentShape(Rectangle())
        .onTapGesture {
          isExpand.toggle()
        }
      
      VStack(spacing: 0) {
        FlowLayout(
          items: viewModel.promotionTags,
          hSpacing: 16,
          vSpacing: 16)
        { promotionTag in
          FilterCell(
            name: promotionTag.name,
            isSelected: promotionTag.filter == viewModel.selectedPromotionFilter,
            onTap: {
              viewModel.selectedPromotionFilter = promotionTag.filter
            })
        }
        .padding(30)

        if viewModel.selectedPromotionFilter == .product {
          Separator(color: .textSecondary, lineWeight: 0.5)
            .padding(.horizontal, 30)

          FlowLayout(
            items: productFilters,
            hSpacing: 16,
            vSpacing: 16)
          { productFilter in
            let isSelected = viewModel.selectedProductFilters.contains(productFilter)

            FilterCell(
              name: productFilter.name,
              isSelected: isSelected,
              onTap: {
                if isSelected {
                  viewModel.selectedProductFilters.remove(productFilter)
                }
                else {
                  viewModel.selectedProductFilters.insert(productFilter)
                }
              })
          }
          .padding(30)
        }
      }
      .backgroundColor(.greyScaleList)
    }
  }
}

extension PromotionDropDownFilter {
  // MARK: - FilterCell
  
  struct FilterCell: View {
    private let name: String
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    
    init(
      name: String,
      isSelected: Bool,
      onTap: (() -> Void)?)
    {
      self.name = name
      self.isSelected = isSelected
      self.onTap = onTap
    }
    
    var body: some View {
      Text(name)
        .localized(
          weight: .regular,
          size: 12,
          color: isSelected
            ? .complementaryDefault
            : .textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .backgroundColor(.inputDefault, cornerRadius: 2)
        .strokeBorder(
          color: isSelected
            ? .complementaryDefault
            : .inputDefault,
          cornerRadius: 2,
          lineWidth: 1)
        .onTapGesture {
          onTap?()
        }
    }
  }
}

// MARK: - Previews

struct PromotionDropDownFilter_Previews: PreviewProvider {
  class FakeViewModel: CouponFilterable {
    @Published var promotionTags: [PromotionTag] = [
      .init(isSelected: false, filter: .all, count: 19),
      .init(isSelected: false, filter: .manual, count: 3),
      .init(isSelected: false, filter: .cashBack, count: 2),
      .init(isSelected: false, filter: .freeBet, count: 2),
      .init(isSelected: false, filter: .depositReturn, count: 3),
      .init(isSelected: false, filter: .product, count: 6),
      .init(isSelected: false, filter: .rebate, count: 3)
    ]
    @Published var selectedPromotionFilter: PromotionFilter = .product
    @Published var selectedProductFilters: Set<PromotionFilter.Product> = [
      .Sport,
      .Arcade
    ]
  }
  
  static var previews: some View {
    VStack {
      PromotionDropDownFilter(viewModel: FakeViewModel())

      Spacer()
    }
  }
}

// MARK: - Deprecated: From Old PromotionFilterDropDown

@available(*, deprecated, message: "Waiting Refactor.")
enum PromotionFilter: CaseIterable {
  case all
  case manual
  case freeBet
  case depositReturn
  case product
  case rebate
  case cashBack
  var tagId: Int {
    switch self {
    case .all:
      return 100
    case .manual:
      return 101
    case .freeBet:
      return 102
    case .depositReturn:
      return 103
    case .product:
      return 104
    case .rebate:
      return 105
    case .cashBack:
      return 106
    }
  }

  var name: String {
    switch self {
    case .all:
      return Localize.string("bonus_bonustype_all_count")
    case .manual:
      return Localize.string("bonus_bonustype_manual_count")
    case .freeBet:
      return Localize.string("bonus_bonustype_1_count")
    case .depositReturn:
      return Localize.string("bonus_bonustype_2_count")
    case .product:
      return Localize.string("bonus_bonustype_3_count")
    case .rebate:
      return Localize.string("bonus_bonustype_4_count")
    case .cashBack:
      return Localize.string("bonus_bonustype_7_count")
    }
  }

  enum Product: Int {
    case Sport = 200
    case Slot
    case Casino
    case Numbergame
    case Arcade

    var name: String {
      switch self {
      case .Sport:
        return Localize.string("common_sportsbook")
      case .Slot:
        return Localize.string("common_slot")
      case .Casino:
        return Localize.string("common_casino")
      case .Numbergame:
        return Localize.string("common_keno")
      case .Arcade:
        return Localize.string("common_arcade")
      }
    }

    var iconId: Int {
      self.rawValue + 100
    }
  }
}

@available(*, deprecated, message: "Waiting Refactor.")
class PromotionTag: Equatable {
  var tagId: Int
  private(set) var name = "" {
    didSet {
      rxName.accept(name)
    }
  }

  var rxName = BehaviorRelay<String>(value: "")
  var isSelected: Bool
  private(set) var count: Int
  private(set) var filter: PromotionFilter

  init(isSelected: Bool, filter: PromotionFilter, count: Int) {
    self.tagId = filter.tagId
    self.isSelected = isSelected
    self.filter = filter
    self.count = count
    defer {
      self.name = String(format: filter.name, "\(count)")
    }
  }

  fileprivate func updateCount(_ count: Int) {
    self.name = String(format: filter.name, "\(count)")
  }

  static func == (lhs: PromotionTag, rhs: PromotionTag) -> Bool {
    lhs.tagId == rhs.tagId
  }
}

@available(*, deprecated, message: "Waiting Refactor.")
class PromotionProductTag: Equatable {
  var tagId: Int
  var iconTagId: Int
  var name: String
  var isSelected: Bool
  private(set) var filter: PromotionFilter.Product

  init(isSelected: Bool, filter: PromotionFilter.Product) {
    self.tagId = filter.rawValue
    self.iconTagId = filter.iconId
    self.isSelected = isSelected
    self.name = filter.name
    self.filter = filter
  }

  static func == (lhs: PromotionProductTag, rhs: PromotionProductTag) -> Bool {
    lhs.tagId == rhs.tagId && lhs.isSelected == rhs.isSelected
  }
}
