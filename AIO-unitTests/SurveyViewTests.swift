import Combine
import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class SurveyViewTests: XCTestCase {
    private func getStubQuestion(
        type: CustomerServiceDTO.CSSurveySurveyQuestionType,
        isRequired: Bool = false)
        -> CustomerServiceDTO.CSSurveyCSQuestion
    {
        CustomerServiceDTO.CSSurveyCSQuestion(
            description: "",
            questionId: "",
            csOption: [],
            isRequired: isRequired,
            type: type)
    }
  
    func test_givenVietnamPlayerAndDescriptionQuestion_whenInput301Characters_thenDisplayPrefix300Characters_KTO_TC_125() {
        let sut = InspectWrapper(
            content: SurveyView(
                survey: CustomerServiceDTO
                    .CSSurvey(
                        heading: "",
                        description: "",
                        surveyId: "",
                        questions: [getStubQuestion(type: .textField)]),
                supportLocale: .Vietnam(),
                submitButtonOnTap: { _ in }))
    
        let expection = sut.inspection.inspect { view in
            let question = try view.find(viewWithId: "descriptionQuestion")
                .view(SurveyView.DescriptionQuestion.self)
                .actualView()
      
            XCTAssertEqual(expect: 300, actual: question.getMaxLength(.Vietnam()))
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection], timeout: 30)
    }
  
    func test_givenChinaPlayerAndDescriptionQuestion_whenInput101Characters_thenDisplayPrefix100Characters_KTO_TC_126() {
        let sut = InspectWrapper {
            SurveyView(
                survey: CustomerServiceDTO
                    .CSSurvey(
                        heading: "",
                        description: "",
                        surveyId: "",
                        questions: [getStubQuestion(type: .textField)]),
                supportLocale: .China(),
                submitButtonOnTap: { _ in })
        }
    
        let expection = sut.inspection.inspect { view in
            let question = try view.find(viewWithId: "descriptionQuestion")
                .view(SurveyView.DescriptionQuestion.self)
                .actualView()
      
            XCTAssertEqual(expect: 100, actual: question.getMaxLength(.China()))
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection], timeout: 30)
    }
  
    func test_givenHasRequiredQuestion_thenDisplayRequiredHint_KTO_TC_127() {
        let sut = InspectWrapper {
            SurveyView(
                survey: CustomerServiceDTO
                    .CSSurvey(
                        heading: "",
                        description: "",
                        surveyId: "",
                        questions: [
                            getStubQuestion(type: .simpleOption, isRequired: true),
                            getStubQuestion(type: .multipleOption, isRequired: true),
                            getStubQuestion(type: .textField, isRequired: true)
                        ]),
                supportLocale: .China(),
                submitButtonOnTap: { _ in })
        }

        let expection1 = sut.inspection.inspect { view in
            let isRequiredHintExist = try view
                .find(viewWithId: "simpleOptionQuestion")
                .isExistByVisibility(viewWithId: "requiredHint")
      
            XCTAssertTrue(isRequiredHintExist)
        }

        let expection2 = sut.inspection.inspect { view in
            let isRequiredHintExist = try view
                .find(viewWithId: "multipleOptionQuestion")
                .isExistByVisibility(viewWithId: "requiredHint")
      
            XCTAssertTrue(isRequiredHintExist)
        }
    
        let expection3 = sut.inspection.inspect { view in
            let isRequiredHintExist = try view
                .find(viewWithId: "descriptionQuestion")
                .isExistByVisibility(viewWithId: "requiredHint")
      
            XCTAssertTrue(isRequiredHintExist)
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection1, expection2, expection3], timeout: 30)
    }
  
    func test_givenNoRequiredQuestionAndNoneOfQuestionsAnswered_thenSurveyCanSubmit_KTO_TC_128() {
        let sut = InspectWrapper {
            SurveyView(
                survey: CustomerServiceDTO.CSSurvey(
                    heading: "",
                    description: "",
                    surveyId: "",
                    questions: [
                        getStubQuestion(type: .simpleOption)
                    ]),
                supportLocale: .Vietnam(),
                submitButtonOnTap: { _ in })
        }
    
        let expection = sut.inspection.inspect { view in
            let isSumitButtonDisable = try view.isAsyncButtonDisable(viewWithId: "submitButton")
            XCTAssertFalse(isSumitButtonDisable)
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection], timeout: 30)
    }
  
    func test_givenRequiredQuestionAndQuestionsAnswered_thenSurveyCanSubmit_KTO_TC_903() {
        let stubOption = CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "1", values: "testOption")
        let stubQuestion = CustomerServiceDTO.CSSurveyCSQuestion(
            description: "",
            questionId: "",
            csOption: [stubOption],
            isRequired: true,
            type: .multipleOption)
    
        let sut = SurveyView(
            survey: CustomerServiceDTO.CSSurvey(
                heading: "",
                description: "",
                surveyId: "",
                questions: [
                    stubQuestion
                ]),
            supportLocale: .Vietnam(),
            submitButtonOnTap: { _ in })
  
        let publisher = PassthroughSubject<Void, Never>()
    
        let expection = sut.inspection.inspect { view in
            try view
                .find(viewWithId: "surveyView")
                .callOnChange(newValue: [stubQuestion: [stubOption]])
            publisher.send(())
        }
    
        let expection1 = sut.inspection.inspect { view in
            let isSumitButtonDisable = try view.isAsyncButtonDisable(viewWithId: "submitButton")
            XCTAssertFalse(isSumitButtonDisable)
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection, expection1], timeout: 30)
    }
  
    func test_givenRequiredQuestionAndNoneOfQuestionsAnswered_thenSurveyCanSubmit_KTO_TC_904() {
        let stubOption = CustomerServiceDTO.CSSurveyCSQuestionOptions(optionId: "1", values: "testOption")
        let stubQuestion = CustomerServiceDTO.CSSurveyCSQuestion(
            description: "",
            questionId: "",
            csOption: [stubOption],
            isRequired: true,
            type: .multipleOption)
    
        let sut = SurveyView(
            survey: CustomerServiceDTO.CSSurvey(
                heading: "",
                description: "",
                surveyId: "",
                questions: [
                    stubQuestion
                ]),
            supportLocale: .Vietnam(),
            submitButtonOnTap: { _ in })
    
        let expection = sut.inspection.inspect { view in
            let isSumitButtonDisable = try view.isAsyncButtonDisable(viewWithId: "submitButton")
            XCTAssertTrue(isSumitButtonDisable)
        }
    
        ViewHosting.host(view: sut)
        wait(for: [expection], timeout: 30)
    }
}
