import SwiftUI
import Combine

extension SwiftUIDropDownText {
    enum Identifier: String {
        case arrow
        case candidateWordList
        case entireView
    }
}

extension SwiftUIDropDownText {
    enum FeatureType: Equatable {
        case input
        case select
        
        static func == (lhs: SwiftUIDropDownText.FeatureType, rhs: SwiftUIDropDownText.FeatureType) -> Bool {
            switch (lhs, rhs) {
            case (.input, .input):
                return true
            case (.select, .select):
                return true
            default:
                return false
            }
        }
    }
}

struct SwiftUIDropDownText: View {
    
    @State private var isInTopSide: Bool = true
    @State private var viewHeight: CGFloat = 0
    
    @State private var isEditing: Bool = false
    
    @State private var filteredItems: [String] = []
  
    @Binding var textFieldText: String
    
    private let placeHolder: String
    private let items: [String]
    
    private let featureType: FeatureType
    private let dropDownArrowVisible: Bool
    
    private let errorText: String
    
    let inspection = Inspection<Self>()
    
    init(
        placeHolder: String,
        textFieldText: Binding<String>,
        errorText: String = "",
        items: [String],
        featureType: FeatureType,
        dropDownArrowVisible: Bool = true
    ) {
        self.placeHolder = placeHolder
        self._textFieldText = textFieldText
        self.errorText = errorText
        self.items = items
        self.featureType = featureType
        self.dropDownArrowVisible = dropDownArrowVisible
    }
    
    var body: some View {
        SwiftUIInputText(
            placeHolder: placeHolder,
            textFieldText: $textFieldText,
            errorText: errorText,
            featureType: dropDownArrowVisible ? .other : .nil,
            textFieldType: GeneralType(regex: .all),
            disableInput: featureType == .select ? true : false,
            isEditing: $isEditing
        )
        .positionDetect(result: $isInTopSide)
        .overlay(
            GeometryReader { geometryProxy in
                Color.clear
                    .onAppear {
                        viewHeight = geometryProxy.size.height
                    }
                    .onChange(of: geometryProxy.size) { size in
                        
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewHeight = size.height
                        }
                    }
            }
        )
        .overlay(
            Image("DropDown")
                .rotationEffect(
                    .degrees(isEditing ? 180 : 0),
                    anchor: .center
                )
                .id(Identifier.arrow.rawValue)
                .visibility(dropDownArrowVisible ? .visible : .invisible)
                .alignmentGuide(.trailing, computeValue: { $0[.trailing] + 15 })
                .allowsHitTesting(false),
            alignment: .trailing
        )
        .overlay(
            topSideDetectList,
            alignment: isInTopSide ? .top: .bottom
        )
        .onAppear {
            filteredItems = items
        }
        .onChange(of: items) { newItems in
            filteredItems = newItems
        }
        .onChange(of: textFieldText) { keyword in
            guard featureType == .input else { return }
            
            if keyword.isEmpty {
                filteredItems = items
            }
            else {
                filteredItems = items.filter { itemDescription in
                    itemDescription.contains(keyword)
                }
            }
        }
        .zIndex(1)
        .onInspected(inspection, self)
        .id(Identifier.entireView.rawValue)
    }
   
  // MARK: - TopSideDetectList
  
    var topSideDetectList: some View {
        VStack(alignment: .leading ,spacing: 0) {
            Image("Triangle16x8")
                .alignmentGuide(.leading, computeValue: { $0[.leading] - 20})
                .visibility(isInTopSide ? .visible : .invisible)
            
            ZStack {
                Color.from(.gray2B2B2B)
                    .cornerRadius(8)
                
                ScrollView(showsIndicators: false) {
                    if filteredItems.isEmpty {
                        Text(Localize.string("common_empty_data"))
                            .localized(
                                weight: .regular,
                                size: 16,
                                color: .gray595959
                            )
                            .frame(height: 74)
                    }
                    else {
                        VStack(spacing: 0) {
                            ForEach(filteredItems, id: \.self) { itemDescription in
                                Text(itemDescription)
                                    .localized(
                                        weight: .regular,
                                        size: 16,
                                        color: .gray9B9B9B
                                    )
                                    .padding(12)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        textFieldText = itemDescription
                                      
                                        isEditing = false
                                    }
                            }
                            .id(SwiftUIDropDownText.Identifier.candidateWordList.rawValue)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(height: filteredItems.isEmpty ? 72 : 225)
            .zIndex(1)
            
            Image("Triangle16x8")
                .rotationEffect(
                    .degrees(180),
                    anchor: .center
                )
                .alignmentGuide(.leading, computeValue: { $0[.leading] - 20})
                .visibility(isInTopSide ? .invisible : .visible)
        }
        .visibility(isEditing ? .visible : .gone)
        .alignmentGuide(
            .top,
            computeValue: {
                $0[.top] - (viewHeight + 2)
            }
        )
        .alignmentGuide(
            .bottom,
            computeValue: {
                $0[.bottom] + (viewHeight + 2)
            }
        )
    }
}

struct SwiftUIDropDownText_Previews: PreviewProvider {
    
    struct Preview: View {
        
        @EnvironmentObject private var safeAreaMonitor: SafeAreaMonitor
        
        @State private var textFieldText: String = ""
        @State private var selectedItemIndex: Int? = nil
        
        let fakeDatas = ["中国银行", "中国工商银行", "中国农民银行", "中国建设银行", "交通银行", "中國信託", "玉山銀行"]
        
        var body: some View {
            ScrollView {
                VStack {
                    SwiftUIDropDownText(
                        placeHolder: "银行所在省份",
                        textFieldText: $textFieldText,
                        items: fakeDatas,
                        featureType: .input,
                        dropDownArrowVisible: false
                    )
                    .padding(.horizontal, 30)
                    
                    LimitSpacer(150)
                }
                .frame(
                    height: safeAreaMonitor.safeAreaSize.height,
                    alignment: .center
                )
                .pageBackgroundColor(.gray131313)
            }
        }
    }
    
    static var previews: some View {
        SafeAreaReader {
            Preview()
        }
    }
}
