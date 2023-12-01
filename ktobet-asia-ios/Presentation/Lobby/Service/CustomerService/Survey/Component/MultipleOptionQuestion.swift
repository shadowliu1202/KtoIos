import sharedbu
import SwiftUI

extension SurveyView {
  struct MultipleOptionQuestion: View {
    @Binding private var answers: [CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]
    
    let question: CustomerServiceDTO.CSSurveyCSQuestion
    
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
          
          ForEach(question.csOption) { option in
            let isLast = question.csOption.last?.optionId == option.optionId
            
            Option(option, isLast) { isSelected in
              if isSelected { addOption(option) }
              else { removeOption(option) }
            }
          }
          
          Separator()
        }
        .backgroundColor(.greyScaleList)
      }
    }
    
    func addOption(_ option: CustomerServiceDTO.CSSurveyCSQuestionOptions) {
      answers[question] = (answers[question] ?? []) + [option]
    }
    
    func removeOption(_ option: CustomerServiceDTO.CSSurveyCSQuestionOptions) {
      answers[question]?.removeAll { $0 == option }
      
      if answers[question]?.isEmpty == true {
        answers.removeValue(forKey: question)
      }
    }
  }
}

extension SurveyView.MultipleOptionQuestion {
  struct Option: View {
    @State private var isSelected = false
    
    let option: CustomerServiceDTO.CSSurveyCSQuestionOptions
    let isLast: Bool
    let onTap: (_ isSelected: Bool) -> Void
    
    init(
      _ option: CustomerServiceDTO.CSSurveyCSQuestionOptions,
      _ isLast: Bool,
      onTap: @escaping (_ isSelected: Bool) -> Void)
    {
      self.option = option
      self.isLast = isLast
      self.onTap = onTap
    }
    
    var body: some View {
      VStack(spacing: 0) {
        HStack(spacing: 8) {
          Text(option.values)
            .localized(weight: .medium, size: 14, color: .greyScaleWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
          
          Image(isSelected ? "iconDoubleSelectionSelected24" : "iconDoubleSelectionEmpty24")
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
          isSelected.toggle()
        }
        
        Separator()
          .padding(.leading, 30)
          .visibility(isLast ? .gone : .visible)
      }
      .onChange(of: isSelected) { currentStatus in
        onTap(currentStatus)
      }
      .id(SurveyView.TestTag.option.rawValue)
    }
  }
}
