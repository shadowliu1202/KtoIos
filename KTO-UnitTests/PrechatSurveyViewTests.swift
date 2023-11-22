import Combine
import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension IPrechatSurveyViewModelMock: ObservableObject { }

final class PrechatSurveyViewTests: XCBaseTestCase {
  func test_givenHasOneQuestionAndTypeIsSingleOption_thenDisplayServeyWithSingleOptionQuestion() {
    let stubViewModel = mock(IPrechatSurveyViewModel.self)
    given(stubViewModel.survey) ~> CustomerServiceDTO.CSSurvey(
      heading: "",
      description: "",
      surveyId: "",
      questions: [CustomerServiceDTO.CSSurveyCSQuestion(
        description: "",
        questionId: "",
        csOption: [],
        isRequired: false,
        type: .simpleoption)])
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.isSubmitButtonDisable) ~> false
    
    let sut = InspectWrapper(content: PrechatSurveyView(viewModel: stubViewModel))
    
    let expection = sut.inspection.inspect { view in
      let questionList = try view.find(viewWithId: "questions").forEach()
      XCTAssertEqual(expect: 1, actual: questionList.count)
      
      let questionView = try questionList
        .find(viewWithId: "question(atIndex: 0)")
        .view(SurveyView.Question.self)
        .actualView()
      
      XCTAssertEqual(
        expect: CustomerServiceDTO.CSSurveySurveyQuestionType.simpleoption,
        actual: questionView.question.type)
    }
    
    ViewHosting.host(view: sut)
    wait(for: [expection], timeout: 30)
  }
  
  func test_givenHasOneQuestionAndTypeIsMultipleOption_thenDisplayServeyWithMultipleOptionQuestion() {
    let stubViewModel = mock(IPrechatSurveyViewModel.self)
    given(stubViewModel.survey) ~> CustomerServiceDTO.CSSurvey(
      heading: "",
      description: "",
      surveyId: "",
      questions: [CustomerServiceDTO.CSSurveyCSQuestion(
        description: "",
        questionId: "",
        csOption: [],
        isRequired: false,
        type: .multipleoption)])
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.isSubmitButtonDisable) ~> false
    
    let sut = InspectWrapper(content: PrechatSurveyView(viewModel: stubViewModel))
    
    let expection = sut.inspection.inspect { view in
      let questionList = try view.find(viewWithId: "questions").forEach()
      XCTAssertEqual(expect: 1, actual: questionList.count)
      
      let questionView = try questionList
        .find(viewWithId: "question(atIndex: 0)")
        .view(SurveyView.Question.self)
        .actualView()
      
      XCTAssertEqual(
        expect: CustomerServiceDTO.CSSurveySurveyQuestionType.multipleoption,
        actual: questionView.question.type)
    }
    
    ViewHosting.host(view: sut)
    wait(for: [expection], timeout: 30)
  }
  
  func test_givenHasOneQuestionAndTypeIsDescription_thenDisplayServeyWithDescriptionQuestion() {
    let stubViewModel = mock(IPrechatSurveyViewModel.self)
    given(stubViewModel.survey) ~> CustomerServiceDTO.CSSurvey(
      heading: "",
      description: "",
      surveyId: "",
      questions: [CustomerServiceDTO.CSSurveyCSQuestion(
        description: "",
        questionId: "",
        csOption: [],
        isRequired: false,
        type: .textfield)])
    given(stubViewModel.getSupportLocale()) ~> .Vietnam()
    given(stubViewModel.isSubmitButtonDisable) ~> false
    
    let sut = InspectWrapper(content: PrechatSurveyView(viewModel: stubViewModel))
    
    let expection = sut.inspection.inspect { view in
      let questionList = try view.find(viewWithId: "questions").forEach()
      XCTAssertEqual(expect: 1, actual: questionList.count)
      
      let questionView = try questionList
        .find(viewWithId: "question(atIndex: 0)")
        .view(SurveyView.Question.self)
        .actualView()
      
      XCTAssertEqual(
        expect: CustomerServiceDTO.CSSurveySurveyQuestionType.textfield,
        actual: questionView.question.type)
    }
    
    ViewHosting.host(view: sut)
    wait(for: [expection], timeout: 30)
  }
}
