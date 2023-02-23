import SharedBu

extension SurveyAnswers {
  func toSurveyAnswerBean() -> [SurveyAnswerBean] {
    self.answers.map({ question, options in
      SurveyAnswerBean(
        questionID: question.questionId,
        questionText: question.description_,
        answer: options.map({ $0.toAnswerBean() }))
    })
  }
}

extension SurveyQuestion_.SurveyQuestionOption {
  func toAnswerBean() -> AnswerBean? {
    let answerID = optionId.isEmpty ? nil : optionId
    return AnswerBean(answerID: answerID, answerText: values, isOther: isOther)
  }
}
