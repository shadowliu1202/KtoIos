import Foundation
import RxSwift
import sharedbu

protocol CustomServiceAPIConvertor {
  func convert(question: Question_) -> Question
  func convert(answerOption: SurveyAnswerOption_) -> SurveyAnswerOption
}

extension CustomServiceAPIConvertor {
  func convert(question: Question_) -> Question {
    Question(
      questionId: question.questionId,
      questionText: question.questionText,
      surveyAnswerOptions: question
        .surveyAnswerOptions
        .map {
          self.convert(answerOption: $0)
        })
  }

  func convert(answerOption: SurveyAnswerOption_) -> SurveyAnswerOption {
    SurveyAnswerOption(optionId: answerOption.optionId, optionText: answerOption.optionText)
  }
}
