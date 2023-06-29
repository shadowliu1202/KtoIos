import Foundation
import RxCocoa
import RxSwift
import SharedBu

class SurveyViewModel {
  let InitAndKeyboardFirstEvent = 2

  private let surveyTempMapper = SurveyTempMapper()
  
  private let surveyAppService: ISurveyAppService
  private let authenticationUseCase: AuthenticationUseCase
  private let disposeBag = DisposeBag()
  
  private var chatSurveyInfo: Survey? {
    didSet {
      cachedSurveyAnswers = chatSurveyInfo?.surveyQuestions.map({
        SurveyAnswerItem($0)
      })
      self.cachedSurvey.accept(chatSurveyInfo)
    }
  }

  var cachedSurvey = BehaviorRelay<Survey?>(value: nil)
  private var cachedSurveyAnswersRelay = BehaviorRelay<[SurveyAnswerItem]?>(value: nil)
  var cachedSurveyAnswers: [SurveyAnswerItem]?
  lazy var isAnswersValid: Observable<Bool> = Observable.combineLatest(cachedSurvey, cachedSurveyAnswersRelay).map({
    info, answers in
    if let survey = info {
      let result = survey.surveyQuestions.reduce(true, { isAnswerRequiredQuestion, question in
        if question.isRequired {
          let item: SurveyAnswerItem? = answers?.first(where: { $0.question == question })
          return isAnswerRequiredQuestion && question.verifyAnswer(options: item?.options.map { $0 })
        }
        else {
          return isAnswerRequiredQuestion
        }
      })
      return result
    }
    return true
  })

  var offlineSurveyAccount = BehaviorRelay<String?>(value: nil)
  var offlineSurveyContent = BehaviorRelay<String?>(value: nil)

  lazy var accontValid: Observable<ValidError> = offlineSurveyAccount.skip(InitAndKeyboardFirstEvent).compactMap({ $0 })
    .map { text -> ValidError in
      if text.count == 0 {
        return .empty
      }
      else if !Account.Email(email: text).isValid() {
        return .regex
      }
      else {
        return .none
      }
    }

  private lazy var isAccountValid = accontValid.map({ $0 == .none ? true : false })
  lazy var isSurveyContentValid: Observable<Bool> = offlineSurveyContent.compactMap({ $0 }).map({ !$0.isEmpty })
  lazy var isGuest: Single<Bool> = self.authenticationUseCase.accountValidation().map({ !$0 })
  lazy var isOfflineSurveyValid = isGuest.catch({ _ in Single.just(false) }).asObservable()
    .flatMap({ [unowned self] isGuest -> Observable<Bool> in
      if isGuest {
        return Observable.combineLatest(self.isAccountValid, self.isSurveyContentValid).compactMap({ ($0, $1) })
          .map({ $0 && $1 })
      }
      return self.isSurveyContentValid
    }).startWith(false)

  init(
    _ surveyAppService: ISurveyAppService,
    _ authenticationUseCase: AuthenticationUseCase)
  {
    self.surveyAppService = surveyAppService
    self.authenticationUseCase = authenticationUseCase
  }

  func getPreChatSurvey() -> Single<Survey> {
    Single.from(
      surveyAppService
        .getPreChatSurvey())
      .map { [weak self] csSurveyDTO -> Survey in
        guard let self
        else {
          throw KTOError.LostReference
        }
      
        return self.surveyTempMapper.covertToSurvey(csSurveyDTO)
      }
      .do(afterSuccess: { [weak self] in
        self?.chatSurveyInfo = $0
      })
  }

  func answerUpdate() {
    cachedSurveyAnswersRelay.accept(cachedSurveyAnswers)
  }

  func getExitSurvey(roomId: String) -> Single<Survey> {
    Single.from(
      surveyAppService
        .getExitSurvey(roomId: roomId))
      .map { [weak self] csSurveyDTO -> Survey in
        guard let self
        else {
          throw KTOError.LostReference
        }
        
        return self.surveyTempMapper.covertToSurvey(csSurveyDTO)
      }
      .do(afterSuccess: { [weak self] in
        self?.chatSurveyInfo = $0
      })
  }

  func answerExitSurvey(roomId: RoomId, survey: Survey) -> Completable {
    let surveyAnswers = convertSurveyAnswerItems(with: survey)
    return Completable
      .from(
        surveyAppService
          .answerExitSurvey(
            roomId: roomId,
            answer: surveyTempMapper.convertToCSSurveyAnswersDTO(surveyAnswers)))
  }

  private func convertSurveyAnswerItems(with survey: Survey) -> SurveyAnswers {
    var answers: [SurveyQuestion_: [SurveyQuestion_.SurveyQuestionOption]] = [:]
    cachedSurveyAnswers?.forEach({
      answers[$0.question] = Array($0.options)
    })
    return SurveyAnswers(
      csSkillId: survey.csSkillId,
      surveyId: survey.surveyId,
      answers: answers,
      surveyType: survey.surveyType)
  }

  func createOfflineSurvey() -> Completable {
    let msg = offlineSurveyContent.value ?? ""
    let email = offlineSurveyAccount.value ?? ""
    
    return Completable
      .from(
        surveyAppService
          .answerOfflineSurvey(message: msg, email: email))
  }
}

class SurveyAnswerItem {
  var question: SurveyQuestion_
  var options: Set<SurveyQuestion_.SurveyQuestionOption>

  init(_ question: SurveyQuestion_, _ options: Set<SurveyQuestion_.SurveyQuestionOption> = []) {
    self.question = question
    self.options = options
  }

  func addAnswer(_ option: SurveyQuestion_.SurveyQuestionOption) {
    options.insert(option)
  }

  func removeAnswer(_ option: SurveyQuestion_.SurveyQuestionOption) {
    options.remove(option)
  }

  func isOptionSelected(_ option: SurveyQuestion_.SurveyQuestionOption) -> Bool {
    options.contains(option)
  }
}
