
import SwiftUI

struct PortalMaintenanceView: View {
    @Environment(\.handleError) var handleError
    @StateObject private var viewModel: PortalMaintenanceViewModel = .init()
    @State private var remainTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var timerHours: String = "00"
    @State var timerMinutes: String = "00"
    @State var timerSeconds: String = "00"
    @State var isMaintenanceOver: Bool = false
    
    let dismissHandler: () -> Void

    var body: some View {
        
        VStack(spacing: 0) {

            Image("全站維護")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 50)
                .overlay(
                    GeometryReader { geometry in
                        HStack(spacing: 12) {
                            TimerView(currentTime: timerHours, timeUnit: "h")
                            TimerView(currentTime: timerMinutes, timeUnit: "m")
                            TimerView(currentTime: timerSeconds, timeUnit: "s")
                        }
                        .position(x: geometry.size.width * 0.51, y: geometry.size.height * 0.52)
                    }
                    , alignment: .center
                )

            LimitSpacer(40)
      
            Text(LocalizedStringKey("common_maintenance_description_parameterize \(Text("common_kto") .foregroundColor(.red))"))
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            LimitSpacer(24)

            Text("common_all_maintenance")
                .font(weight: .semibold, size: 18)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                

            LimitSpacer(40)

            Text("common_cs_email_description")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            LimitSpacer(8)

            Text(viewModel.supportEmail)
                .foregroundColor(.red)
                .onTapGesture {
                    let email = viewModel.supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !email.isEmpty, let url = URL(string: "mailto:\(email)") else { return }
                    UIApplication.shared.open(url)
                }
                .padding(.horizontal, 30)
   
            Spacer()
        }
        .onAppear(perform: {
            viewModel.systemStatusUseCase.refreshMaintenanceState()
        })
        .background(Color("blackTwo"))
        .onChange(of: isMaintenanceOver) { isMaintenanceOver in
            if isMaintenanceOver {
                dismissHandler()
            }
        }
        .onReceive(remainTimer) { _ in
            guard let remainSeconds = viewModel.remainSeconds else { return }
            if remainSeconds > 0 {
                let newRemainSeconds = remainSeconds - 1
                viewModel.remainSeconds = newRemainSeconds
                updateRemainingTime(newRemainSeconds)
            } else {
                isMaintenanceOver = true
            }
        }
        .onConsume(handleError, viewModel) { event in
            switch event {
                
            case .isMaintenanceOver:
                isMaintenanceOver = true
            }
            
        }
       
    }

    private func updateRemainingTime(_ countDownSecond: Int) {
        timerHours = String(format: "%02d", countDownSecond / 3600)
        timerMinutes = String(format: "%02d", (countDownSecond / 60) % 60)
        timerSeconds = String(format: "%02d", countDownSecond % 60)
    }
}

struct TimerView: View {
    let currentTime: String
    let timeUnit: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text(currentTime)
                .font(weight: .semibold, size: 32)
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
            Text(timeUnit)
                .font(weight: .semibold, size: 12)
                .alignmentGuide(.bottom) { d in d[.firstTextBaseline] }
        }
    }
}

struct PortalMaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        PortalMaintenanceView(dismissHandler: {
            print("Dismiss handler triggered")

        })
    }
}
