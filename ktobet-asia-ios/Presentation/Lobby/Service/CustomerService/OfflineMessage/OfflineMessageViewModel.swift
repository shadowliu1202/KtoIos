import Combine
import Foundation
import RxCocoa
import RxSwift
import sharedbu

protocol OfflineMessageViewModelProtocol: AnyObject {
  var isLogin: Bool { get }
  var isAllowSubmit: Bool { get }
  var emailErrorText: String { get }
  var email: String { get set }
  var content: String { get set }
  
  func createOfflineSurvey() async
}

final class OfflineMessageViewModel:
  ErrorCollectViewModel,
  ObservableObject,
  OfflineMessageViewModelProtocol
{
  @Published private(set) var isLogin = false
  @Published private(set) var isAllowSubmit = false
  @Published private(set) var emailErrorText = ""
  
  @Published var email = ""
  @Published var content = ""
  
  private let surveyAppService: ISurveyAppService
  private let authenticationUseCase: AuthenticationUseCase
  
  private let disposeBag = DisposeBag()
  
  private var cancellables = Set<AnyCancellable>()
  
  init(
    _ surveyAppService: ISurveyAppService,
    _ authenticationUseCase: AuthenticationUseCase)
  {
    self.surveyAppService = surveyAppService
    self.authenticationUseCase = authenticationUseCase
    super.init()
    
    getLoginState()
    getEmailErrorText()
  }
  
  private func getLoginState() {
    authenticationUseCase.accountValidation()
      .subscribe(onSuccess: { [unowned self] in
        self.isLogin = $0
        self.updateButtonState($0)
      })
      .disposed(by: disposeBag)
  }
  
  private func getEmailErrorText() {
    $email
      .dropFirst()
      .map { self.convertToEmailErrorType(text: $0) }
      .map { self.transferErrorText($0) }
      .assign(to: &$emailErrorText)
  }
  
  private func updateButtonState(_ isLogin: Bool) {
    Publishers.CombineLatest3(
      $email.map { isLogin ? true : !$0.isEmpty },
      $content.map { !$0.isEmpty },
      $emailErrorText.map { isLogin ? true : $0.isEmpty })
      .map { $0 && $1 && $2 }
      .assign(to: &$isAllowSubmit)
  }
  
  private func convertToEmailErrorType(text: String) -> ValidError {
    if text.isEmpty {
      return .empty
    }
    else if !Account.Email(email: text).isValid() {
      return .regex
    }
    else {
      return .none
    }
  }
  
  private func transferErrorText(_ error: ValidError) -> String {
    switch error {
    case .length,
         .regex:
      return Localize.string("common_error_email_format")
    case .empty:
      return Localize.string("common_field_must_fill")
    case .none:
      return ""
    }
  }
  
  func createOfflineSurvey() async {
    await AnyPublisher.from(
      surveyAppService
        .answerOfflineSurvey(message: content, email: email))
      .receive(on: DispatchQueue.main)
      .redirectErrors(to: self)
      .valueWithoutError
  }
}
