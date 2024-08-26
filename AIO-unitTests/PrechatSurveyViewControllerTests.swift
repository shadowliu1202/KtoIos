import Combine
import Mockingbird
import sharedbu
import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

final class PrechatSurveyViewControllerTests: XCBaseTestCase {
    private func getStubSurveyBean(questions: [SurveyQuestion_]) -> Survey {
        Survey(
            copyFrom: "",
            createdDate: "",
            createdUser: nil,
            description: nil,
            enable: true,
            heading: nil,
            isAskLogin: false,
            isEverOnline: true,
            isOnline: true,
            skillId: "",
            subject: nil,
            surveyId: "",
            surveyQuestions: questions,
            surveyType: 0,
            updatedDate: "",
            updatedUser: nil,
            version: 0)
    }
  
    private func getStubQuestionBean(questionType: CustomerServiceDTO.CSSurveySurveyQuestionType) -> SurveyQuestion_ {
        let surveyQuestionType: Int32
    
        switch questionType {
        case .simpleOption: surveyQuestionType = 1
        case .multipleOption: surveyQuestionType = 2
        case .textField: surveyQuestionType = 6
        }
    
        return SurveyQuestion_(
            aim: "",
            createdDate: "",
            createdUser: "",
            description: "",
            enable: true,
            isLogin: false,
            isNotLogin: false,
            isRequired: false,
            isVisible: true,
            questionId: "",
            sort: 0,
            surveyId: "",
            surveyQuestionOptions: [SurveyQuestionOption_(
                createdDate: "",
                createdUser: "",
                enable: true,
                isOther: false,
                optionId: "",
                questionId: "",
                values: "")],
            surveyQuestionType: surveyQuestionType)
    }
  
    func test_givenHasOneQuestionAndTypeIsSingleOption_thenDisplayServeyWithSingleOptionQuestion_KTO_TC_122() {
        let stubCSSurveyAdapter = mock(CSSurveyAdapter.self).initialize(getFakeHttpClient())
        given(stubCSSurveyAdapter.getSkillSurvey(type: any())) ~> Single.just(ResponseItem(
            data: self.getStubSurveyBean(questions: [self.getStubQuestionBean(questionType: .simpleOption)]),
            errorMsg: "",
            node: "",
            statusCode: "200"))
            .asWrapper()
    
        injectFakeObject(CSSurveyProtocol.self, object: stubCSSurveyAdapter)
    
        let sut = PrechatSurveyViewController()
        sut.loadViewIfNeeded()
        let hostingController = (sut.children.first! as! UIHostingController<PrechatSurveyView<PrechatSurveyViewModel>>)
        let prechatServeyView = InspectWrapper(content: hostingController.rootView)
        let publisher = PassthroughSubject<Void, Never>()
    
        let expection = prechatServeyView.inspection.inspect { view in
            _ = try view.find(viewWithId: "loading")
            publisher.send(())
        }
    
        let expection1 = prechatServeyView.inspection.inspect(onReceive: publisher) { view in
            let questionList = try view.find(viewWithId: "questions").forEach()
            XCTAssertEqual(expect: 1, actual: questionList.count)
      
            let questionView = try questionList
                .find(viewWithId: "question(atIndex: 0)")
                .view(SurveyView.Question.self)
                .actualView()
      
            XCTAssertEqual(
                expect: CustomerServiceDTO.CSSurveySurveyQuestionType.simpleOption,
                actual: questionView.question.type)
        }
    
        ViewHosting.host(view: prechatServeyView)
        wait(for: [expection, expection1], timeout: 30)
    }
  
    func test_givenHasOneQuestionAndTypeIsMultipleOption_thenDisplayServeyWithMultipleOptionQuestion_KTO_TC_123() {
        let stubCSSurveyAdapter = mock(CSSurveyAdapter.self).initialize(getFakeHttpClient())
        given(stubCSSurveyAdapter.getSkillSurvey(type: any())) ~> Single.just(ResponseItem(
            data: self.getStubSurveyBean(questions: [self.getStubQuestionBean(questionType: .multipleOption)]),
            errorMsg: "",
            node: "",
            statusCode: "200"))
            .asWrapper()
    
        injectFakeObject(CSSurveyProtocol.self, object: stubCSSurveyAdapter)
    
        let sut = PrechatSurveyViewController()
        sut.loadViewIfNeeded()
        let hostingController = (sut.children.first! as! UIHostingController<PrechatSurveyView<PrechatSurveyViewModel>>)
        let prechatServeyView = InspectWrapper(content: hostingController.rootView)
        let publisher = PassthroughSubject<Void, Never>()
    
        let expection = prechatServeyView.inspection.inspect { view in
            _ = try view.find(viewWithId: "loading")
            publisher.send(())
        }
    
        let expection1 = prechatServeyView.inspection.inspect(onReceive: publisher) { view in
            let questionList = try view.find(viewWithId: "questions").forEach()
            XCTAssertEqual(expect: 1, actual: questionList.count)
      
            let questionView = try questionList
                .find(viewWithId: "question(atIndex: 0)")
                .view(SurveyView.Question.self)
                .actualView()
      
            XCTAssertEqual(
                expect: CustomerServiceDTO.CSSurveySurveyQuestionType.multipleOption,
                actual: questionView.question.type)
        }
    
        ViewHosting.host(view: prechatServeyView)
        wait(for: [expection, expection1], timeout: 30)
    }
  
    func test_givenHasOneQuestionAndTypeIsDescription_thenDisplayServeyWithDescriptionQuestion_KTO_TC_124() {
        let stubCSSurveyAdapter = mock(CSSurveyAdapter.self).initialize(getFakeHttpClient())
        given(stubCSSurveyAdapter.getSkillSurvey(type: any())) ~> Single.just(ResponseItem(
            data: self.getStubSurveyBean(questions: [self.getStubQuestionBean(questionType: .textField)]),
            errorMsg: "",
            node: "",
            statusCode: "200"))
            .asWrapper()
    
        injectFakeObject(CSSurveyProtocol.self, object: stubCSSurveyAdapter)
    
        let sut = PrechatSurveyViewController()
        sut.loadViewIfNeeded()
        let hostingController = (sut.children.first! as! UIHostingController<PrechatSurveyView<PrechatSurveyViewModel>>)
        let prechatServeyView = InspectWrapper(content: hostingController.rootView)
        let publisher = PassthroughSubject<Void, Never>()
    
        let expection = prechatServeyView.inspection.inspect { view in
            _ = try view.find(viewWithId: "loading")
            publisher.send(())
        }
    
        let expection1 = prechatServeyView.inspection.inspect(onReceive: publisher) { view in
            let questionList = try view.find(viewWithId: "questions").forEach()
            XCTAssertEqual(expect: 1, actual: questionList.count)
      
            let questionView = try questionList
                .find(viewWithId: "question(atIndex: 0)")
                .view(SurveyView.Question.self)
                .actualView()
      
            XCTAssertEqual(
                expect: CustomerServiceDTO.CSSurveySurveyQuestionType.textField,
                actual: questionView.question.type)
        }
    
        ViewHosting.host(view: prechatServeyView)
        wait(for: [expection, expection1], timeout: 30)
    }
}
