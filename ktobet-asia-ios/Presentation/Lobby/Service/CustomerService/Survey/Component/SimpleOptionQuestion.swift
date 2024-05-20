import sharedbu
import SwiftUI

extension SurveyView {
    struct SimpleOptionQuestion: View {
        @State private var selectedValue: String? = nil
        @State private var isFocus = false
    
        @Binding private var answers: [CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]
    
        private let question: CustomerServiceDTO.CSSurveyCSQuestion
        private let id = UUID()
    
        init(
            _ question: CustomerServiceDTO.CSSurveyCSQuestion,
            _ answers: Binding<[CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]>)
        {
            self.question = question
            self._answers = answers
        }
    
        var body: some View {
            VStack(spacing: 12) {
                SurveyView.QuestionHeader(question)
        
                VStack(spacing: 0) {
                    Separator()
          
                    HStack(spacing: 8) {
                        Text(selectedValue ?? Localize.string("common_please_select"))
                            .localized(weight: .medium, size: 14, color: .greyScaleWhite)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
            
                        Image("ArrowDropDown")
                            .rotationEffect(.degrees(isFocus ? 180 : 0))
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .backgroundColor(.greyScaleList)
          
                    Separator()
                }
                .onTapGesture {
                    isFocus.toggle()
                    DropDownList.notifyTopSideDetectListShouldCollapse(id: id)
                }
                .overlay(
                    DropDownList(
                        id: id,
                        items: question.csOption.map { $0.values },
                        listStyle: .rectangle,
                        selectedItem: $selectedValue ?? "",
                        isFocus: $isFocus))
            }
            .zIndex(isFocus ? 1 : 0)
            .onChange(of: selectedValue) { newValue in
                guard
                    let newValue,
                    let selectedOption = question.csOption.first(where: { $0.values == newValue })
                else { return }
        
                answers[question] = [selectedOption]
            }
        }
    }
}
