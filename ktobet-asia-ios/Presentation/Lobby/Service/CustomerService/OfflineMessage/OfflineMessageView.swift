import SwiftUI

struct OfflineMessageView<ViewModel>: View
    where ViewModel:
    OfflineMessageViewModelProtocol &
    ObservableObject
{
    @StateObject var viewModel: ViewModel
  
    var submitOnComplete: (() -> Void)?
  
    var body: some View {
        ScrollView {
            PageContainer {
                VStack {
                    Text(key: "update_leave_message")
                        .localized(weight: .semibold, size: 24, color: .greyScaleWhite)
                        .frame(maxWidth: .infinity, alignment: .center)

                    LimitSpacer(30)
          
                    EmailView(
                        email: $viewModel.email,
                        errorText: viewModel.emailErrorText)
                        .visibility(viewModel.isLogin ? .gone : .visible)
          
                    LimitSpacer(12)
          
                    ContentView(content: $viewModel.content)
          
                    LimitSpacer(40)
          
                    PrimaryButton(
                        title: Localize.string("common_done"),
                        action: {
                            await viewModel.createOfflineSurvey()
                            submitOnComplete?()
                        })
                        .disabled(!viewModel.isAllowSubmit)
                }
                .padding(.horizontal, 30)
            }
        }
        .backgroundColor(.greyScaleDefault)
    }
}

extension OfflineMessageView {
    struct EmailView: View {
        @Binding var email: String
    
        var errorText: String
    
        var body: some View {
            SwiftUIInputText(
                placeHolder: Localize.string("common_email"),
                textFieldText: $email,
                errorText: errorText,
                textFieldType: GeneralType(
                    regex: .email,
                    keyboardType: .emailAddress))
        }
    }
}

extension OfflineMessageView {
    struct ContentView: View {
        @Binding var content: String
    
        var body: some View {
            SwiftUITextView(
                placeholder: Localize.string("customerservice_offline_survey_hint"),
                text: $content)
                .frame(height: 128)
        }
    }
}

struct OfflineMessageView_Previews: PreviewProvider {
    class FakeViewModel:
        OfflineMessageViewModelProtocol,
        ObservableObject
    {
        var isLogin = true
        var email = "test@email.com"
        var emailErrorText = "error"
        var content = "content"
        var isAllowSubmit = true
    
        func createOfflineSurvey() async { }
    }
  
    static var previews: some View {
        ZStack(alignment: .top) {
            Color.from(.greyScaleDefault)
                .ignoresSafeArea()
      
            OfflineMessageView(
                viewModel: FakeViewModel())
        }
    }
}
