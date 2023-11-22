import SwiftUI

struct ExitSurveyView<ViewModel>: View
  where ViewModel:
  IExitSurveyViewModel &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel
  
  private let roomID: String
  private let onAnswerSubmitSuccess: () -> Void
    
  init(viewModel: ViewModel, roomID: String, onAnswerSubmitSuccess: @escaping () -> Void) {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.roomID = roomID
    self.onAnswerSubmitSuccess = onAnswerSubmitSuccess
  }
    
  var body: some View {
    VStack {
      if let survey = viewModel.survey {
        SurveyView(
          survey: survey,
          supportLocale: viewModel.getSupportLocale(),
          submitButtonOnTap: { [viewModel] in
            await viewModel.answerExitSurvey(roomID, $0, onSubmitSuccess: onAnswerSubmitSuccess)
          })
      }
      else {
        SwiftUILoadingView()
      }
    }
    .environment(\.playerLocale, viewModel.getSupportLocale())
    .onViewDidLoad {
      viewModel.setup(roomID: roomID)
    }
  }
}
