import sharedbu
import SwiftUI

extension PrechatSurveyView {
    enum TestTag: String {
        case loading
    }
}

struct PrechatSurveyView<ViewModel>: View
    where ViewModel:
    IPrechatSurveyViewModel &
    ObservableObject
{
    @StateObject var viewModel: ViewModel
  
    private let submitButtonOnTap: (_ answer: CustomerServiceDTO.CSSurveyAnswers?) -> Void
    
    init(
        viewModel: ViewModel,
        submitButtonOnTap: @escaping (_ answer: CustomerServiceDTO.CSSurveyAnswers?) -> Void = { _ in })
    {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.submitButtonOnTap = submitButtonOnTap
    }
    
    var body: some View {
        VStack {
            if let survey = viewModel.survey {
                SurveyView(
                    survey: survey,
                    supportLocale: viewModel.getSupportLocale(),
                    isSubmitButtonDisable: viewModel.isSubmitButtonDisable,
                    submitButtonOnTap: submitButtonOnTap)
            }
            else {
                SwiftUILoadingView()
                    .id(PrechatSurveyView.TestTag.loading.rawValue)
            }
        }
        .environment(\.playerLocale, viewModel.getSupportLocale())
        .onViewDidLoad {
            viewModel.setup()
        }
    }
}
