import Combine
import sharedbu
import SwiftUI

extension CallingView {
    enum Identifier: String {
        case queueNumber
    }
}

struct CallingView<ViewModel>: View
    where ViewModel:
    CallingViewModelProtocol &
    ObservableObject
{
    @StateObject var viewModel: ViewModel
  
    @State var isAnimationPlaying = true
  
    var surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?
  
    var inspection = Inspection<Self>()
  
    init(
        viewModel: ViewModel,
        surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?)
    {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.surveyAnswers = surveyAnswers
    }
    
    var body: some View {
        PageContainer {
            VStack(alignment: .center, spacing: 0) {
                Text(Localize.string("customerservice_chat_room_connecting_title"))
                    .localized(weight: .semibold, size: 24, color: .textPrimary)
                    .multilineTextAlignment(.center)
        
                LimitSpacer(12)
        
                Text(Localize.string("customerservice_chat_room_your_queue_number", "\(viewModel.currentNumber)"))
                    .localized(weight: .medium, size: 14, color: .textSecondary)
                    .multilineTextAlignment(.center)
                    .id(CallingView.Identifier.queueNumber)
        
                LimitSpacer(30)
        
                GeometryReader { geometry in
                    SwiftUILottieView(
                        isAnimationPlaying: $isAnimationPlaying,
                        lottieFile: "cs_connection")
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .onReceive(
                            NotificationCenter.default
                                .publisher(for: UIApplication.willEnterForegroundNotification))
                    { _ in
                        isAnimationPlaying = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        isAnimationPlaying = false
                    }
                }
            }
            .padding(.horizontal, 30)
        }
        .onViewDidLoad {
            viewModel.setup(surveyAnswers: surveyAnswers)
        }
        .onInspected(inspection, self)
    }
}

struct CallingView_Previews: PreviewProvider {
    class FakeViewModel:
        CallingViewModelProtocol,
        ObservableObject
    {
        var currentNumber = 100
    
        func setup(surveyAnswers _: CustomerServiceDTO.CSSurveyAnswers?) { }
    }
  
    static var previews: some View {
        CallingView(viewModel: FakeViewModel(), surveyAnswers: nil)
    }
}
