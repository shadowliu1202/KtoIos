import sharedbu
import SwiftUI

extension CustomerServiceDTO.CSSurvey: Identifiable { }
extension CustomerServiceDTO.CSSurveyCSQuestion: Identifiable { }
extension CustomerServiceDTO.CSSurveyCSQuestionOptions: Identifiable { }

extension SurveyView {
    enum TestTag {
        case surveyView
        case questions
        case question(atIndex: Int)
        case simpleOptionQuestion
        case multipleOptionQuestion
        case option
        case descriptionQuestion
        case requiredHint
        case submitButton
    
        var rawValue: String { "\(self)" }
    }
}

struct SurveyView: View {
    @State private var answers: [CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]] = [:]
    @State var isAnswerAvailable: Bool
  
    private let survey: CustomerServiceDTO.CSSurvey
    private let requiredQuestionID: Set<String>
    private let supportLocale: SupportLocale
  
    private let isSubmitButtonDisable: Bool
    private let submitButtonOnTap: (_ answer: CustomerServiceDTO.CSSurveyAnswers?) async -> Void
  
    var inspection = Inspection<Self>()
  
    init(
        survey: CustomerServiceDTO.CSSurvey,
        supportLocale: SupportLocale,
        isSubmitButtonDisable: Bool = false,
        submitButtonOnTap: @escaping (_ answer: CustomerServiceDTO.CSSurveyAnswers?) async -> Void)
    {
        self.survey = survey
    
        let requiredQuestionID = Set(
            survey.questions
                .filter { $0.isRequired }
                .map { $0.questionId })
    
        self.requiredQuestionID = requiredQuestionID
        self.isAnswerAvailable = requiredQuestionID.isEmpty
        self.supportLocale = supportLocale
        self.isSubmitButtonDisable = isSubmitButtonDisable
        self.submitButtonOnTap = submitButtonOnTap
    }

    var body: some View {
        SafeAreaReader(ignoresSafeArea: .container) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    PageContainer(topPadding: 26, bottomPadding: 40) {
                        VStack(spacing: 30) {
                            Header(title: survey.heading, description: survey.description_)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 30)
              
                            ForEach(survey.questions) {
                                let index = survey.questions.firstIndex(of: $0)!
                
                                Question($0, $answers, supportLocale)
                                    .id(SurveyView.TestTag.question(atIndex: index).rawValue)
                            }
                            .id(SurveyView.TestTag.questions.rawValue)
                        }
                    }
                }
        
                PrimaryButton(
                    title: Localize.string("common_done"),
                    action: {
                        let answers = answers.isEmpty ? nil : CustomerServiceDTO.CSSurveyAnswers(
                            surveyId: survey.surveyId,
                            answers: answers)
                        await submitButtonOnTap(answers)
                    })
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .disabled(!isAnswerAvailable)
                    .disabled(isSubmitButtonDisable)
                    .id(SurveyView.TestTag.submitButton.rawValue)
            }
        }
    
        .pageBackgroundColor(.greyScaleDefault)
        .onChange(of: answers) { currentAnswers in
            isAnswerAvailable = isAllRequiredAnswersFilled(currentAnswers)
        }
        .id(SurveyView.TestTag.surveyView.rawValue)
        .onInspected(inspection, self)
    }
  
    func isAllRequiredAnswersFilled(_ answers: [
        CustomerServiceDTO
            .CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]
    ]) -> Bool {
        requiredQuestionID.isSubset(of: Set(answers.map { $0.key.questionId }))
    }
}

extension SurveyView {
    // MARK: - Header
  
    struct Header: View {
        let title: String
        let description: String
    
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .localized(weight: .semibold, size: 24, color: .textPrimary)
        
                Text(description)
                    .localized(weight: .medium, size: 14, color: .textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
  
    // MARK: - Question
  
    struct Question: View {
        @Binding private var answers: [CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]
    
        private let supportLocale: SupportLocale
    
        let question: CustomerServiceDTO.CSSurveyCSQuestion
    
        init(
            _ question: CustomerServiceDTO.CSSurveyCSQuestion,
            _ answers: Binding<[CustomerServiceDTO.CSSurveyCSQuestion: [CustomerServiceDTO.CSSurveyCSQuestionOptions]]>,
            _ supportLocale: SupportLocale)
        {
            self.question = question
            self._answers = answers
            self.supportLocale = supportLocale
        }
    
        var body: some View {
            switch question.type {
            case .simpleOption:
                SurveyView.SimpleOptionQuestion(question, $answers)
                    .id(SurveyView.TestTag.simpleOptionQuestion.rawValue)
            case .multipleOption:
                SurveyView.MultipleOptionQuestion(question, $answers)
                    .id(SurveyView.TestTag.multipleOptionQuestion.rawValue)
            case .textField:
                SurveyView.DescriptionQuestion(question, $answers, supportLocale)
                    .id(SurveyView.TestTag.descriptionQuestion.rawValue)
            }
        }
    }
  
    // MARK: - QuestionHeader
  
    struct QuestionHeader: View {
        let question: CustomerServiceDTO.CSSurveyCSQuestion
    
        init(_ question: CustomerServiceDTO.CSSurveyCSQuestion) {
            self.question = question
        }
    
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(question.description_)
                    .localized(weight: .medium, size: 18, color: .textPrimary)
        
                Text(key: "common_field_must_fill_2")
                    .localized(weight: .regular, size: 12, color: .alert)
                    .id(SurveyView.TestTag.requiredHint.rawValue)
                    .visibility(question.isRequired ? .visible : .gone)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Previews

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyView(
            survey: CustomerServiceDTO.CSSurvey(
                heading: "感谢您使用KTO亚洲在线服务(BO可变动标题)",
                description: "如果您已经有注册帐号，请先登录让客服能更好地为您服务。(BO可变动描述)",
                surveyId: "",
                questions: [
                    CustomerServiceDTO.CSSurveyCSQuestion(
                        description: "下拉式问题(BO可变动标题)",
                        questionId: "1",
                        csOption: [
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "1", values: "选项 A"),
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "2", values: "选项 B"),
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "3", values: "选项 C")
                        ],
                        isRequired: true,
                        type: .simpleOption),
                    CustomerServiceDTO.CSSurveyCSQuestion(
                        description: "复选问题(BO可变动标题)",
                        questionId: "2",
                        csOption: [
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "1", values: "选项 A"),
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "2", values: "选项 B"),
                            CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "3", values: "选项 C")
                        ],
                        isRequired: true,
                        type: .multipleOption),
                    CustomerServiceDTO.CSSurveyCSQuestion(
                        description: "描述问题(BO可变动标题)",
                        questionId: "3",
                        csOption: [],
                        isRequired: true,
                        type: .textField)
                ]),
            supportLocale: .China(),
            submitButtonOnTap: { _ in })
    }
}
