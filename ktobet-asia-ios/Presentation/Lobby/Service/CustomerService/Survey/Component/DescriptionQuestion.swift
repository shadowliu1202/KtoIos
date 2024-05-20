import sharedbu
import SwiftUI

extension SurveyView {
    struct DescriptionQuestion: View {
        @State private var text = ""
    
        @Binding private var answers: [CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]
    
        private let question: CustomerServiceDTO.CSSurveyCSQuestion
        private let optionID: String
        private let supportLocale: SupportLocale
    
        init(
            _ question: CustomerServiceDTO.CSSurveyCSQuestion,
            _ answers: Binding<[CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]>,
            _ supportLocale: SupportLocale)
        {
            self.question = question
            self.optionID = question.csOption.first?.optionId ?? ""
            self._answers = answers
            self.supportLocale = supportLocale
        }
    
        var body: some View {
            VStack(spacing: 12) {
                SurveyView.QuestionHeader(question)
        
                SwiftUITextView(
                    placeholder: Localize.string("customerservice_offline_survey_hint"),
                    text: $text,
                    maxLength: getMaxLength(supportLocale))
                    .frame(height: 128)
                    .padding(.horizontal, 30)
            }
            .onChange(of: text) { newValue in
                if text.isEmpty {
                    answers.removeValue(forKey: question)
                }
                else {
                    answers[question] = [CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: optionID, values: newValue)]
                }
            }
        }
    
        func getMaxLength(_ supportLocale: SupportLocale) -> Int {
            switch onEnum(of: supportLocale) {
            case .china:
                return 100
            case .vietnam:
                return 300
            }
        }
    }
}
