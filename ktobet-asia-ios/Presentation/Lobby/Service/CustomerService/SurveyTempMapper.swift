import sharedbu

@available(*, deprecated, message: "should be removed after ui refactor")
class SurveyTempMapper {
  func covertToSurvey(_ csSurveyDTO: CustomerServiceDTO.CSSurvey) -> Survey {
    .init(
      csSkillId: "",
      surveyId: csSurveyDTO.surveyId,
      description: csSurveyDTO.description_,
      surveyType: .exit,
      surveyQuestions: csSurveyDTO.questions
        .map { csQuestionDTO in
          convertToSurveyQuestion(csQuestionDTO)
        },
      enable: true,
      heading: csSurveyDTO.heading,
      isAskLogin: true,
      isEverOnline: true,
      isOnline: true,
      mailFooter: "",
      subject: "",
      version: 0,
      updatedUser: "")
  }
  
  func convertToSurveyQuestion(_ csQuestionDTO: CustomerServiceDTO.CSSurveyCSQuestion) -> SurveyQuestion_ {
    .init(
      questionId: csQuestionDTO.questionId,
      aim: csQuestionDTO.description_,
      createdDate: "",
      description: csQuestionDTO.description_,
      enable: true,
      isLogin: true,
      isNotLogin: true,
      isRequired: csQuestionDTO.isRequired,
      isVisible: true,
      sort: 0,
      surveyId: "",
      surveyQuestionOptions: csQuestionDTO.csOption
        .map { csQuestionOptionsDTO in
          convertToSurveyQuestionOption(questionId: csQuestionDTO.questionId, csQuestionOptionsDTO)
        },
      surveyQuestionType: convertToSurveyQuestionType(csQuestionDTO.type))
  }
  
  func convertToSurveyQuestionOption(
    questionId: String,
    _ csQuestionOptionsDTO: CustomerServiceDTO.CSSurveyCSQuestionOptions)
    -> SurveyQuestion_.SurveyQuestionOption
  {
    .init(
      optionId: csQuestionOptionsDTO.optionId,
      questionId: questionId,
      enable: true,
      isOther: true,
      values: csQuestionOptionsDTO.values)
  }
  
  func convertToSurveyQuestionType(
    _ csSurveyQuestionTypeDTO: CustomerServiceDTO
      .CSSurveySurveyQuestionType)
    -> SurveyQuestion_.SurveyQuestionType
  {
    switch csSurveyQuestionTypeDTO {
    case .multipleoption:
      return .multipleoption
    case .simpleoption:
      return .simpleoption
    case .textfield:
      return .textfield
    default:
      fatalError("should not reach here.")
    }
  }
  
  func convertToCSSurveyAnswersDTO(_ surveyAnswers: SurveyAnswers) -> CustomerServiceDTO.CSSurveyAnswers {
    .init(
      surveyId: surveyAnswers.surveyId,
      answers: surveyAnswers.answers
        .reduce(into: [CustomerServiceDTO.CSSurveyCSQuestion: [
          CustomerServiceDTO
            .CSSurveyCSQuestionOptions
        ]](), { result, answer in
          result[convertToCSQuestionDTO(answer.key)] = answer.value.map { convertToCSQuestionOptionsDTO($0) }
        }))
  }
  
  func convertToCSQuestionDTO(_ surveyQuestion: SurveyQuestion_) -> CustomerServiceDTO.CSSurveyCSQuestion {
    .init(
      description: surveyQuestion.description_,
      questionId: surveyQuestion.questionId,
      csOption: surveyQuestion.surveyQuestionOptions.map { convertToCSQuestionOptionsDTO($0) },
      isRequired: surveyQuestion.isRequired,
      type: convertToCSSurveyQuestionType(surveyQuestion.surveyQuestionType))
  }
  
  func convertToCSQuestionOptionsDTO(_ surveyQuestionOption: SurveyQuestion_.SurveyQuestionOption) -> CustomerServiceDTO
    .CSSurveyCSQuestionOptions
  {
    .init(
      optionId: surveyQuestionOption.questionId,
      values: surveyQuestionOption.values)
  }
  
  func convertToCSSurveyQuestionType(_ surveyQuestionType: SurveyQuestion_.SurveyQuestionType) -> CustomerServiceDTO
    .CSSurveySurveyQuestionType
  {
    switch surveyQuestionType {
    case .multipleoption:
      return .multipleoption
    case .simpleoption:
      return .simpleoption
    case .textfield:
      return .textfield
    default:
      fatalError("should not reach here.")
    }
  }
}
