
import SwiftUI

struct PortalMaintenanceView: View {
    @Environment(\.handleError) var handleError
    @StateObject private var viewModel: PortalMaintenance = .init()
    @State private var remainTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var isMaintenanceOver: Bool = false

    let dismissHandler: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image("全站維護")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .overlay(
                    GeometryReader { geometry in
                        HStack(spacing: 12) {
                            let hour = String(format: "%02d", (viewModel.remainSeconds ?? 0) / 3600)
                            let minute = String(format: "%02d", ((viewModel.remainSeconds ?? 0) / 60) % 60)
                            let seconds = String(format: "%02d", (viewModel.remainSeconds ?? 0) % 60)
                            TimerView(currentTime: hour, timeUnit: "h")
                            TimerView(currentTime: minute, timeUnit: "m")
                            TimerView(currentTime: seconds, timeUnit: "s")
                        }
                        .position(x: geometry.size.width * 0.51, y: geometry.size.height * 0.52)
                    },
                    alignment: .center
                )

            LimitSpacer(40)

            Text(
                LocalizedStringKey(
                    "common_maintenance_description_parameterize \(Text("common_kto").foregroundColor(.primaryDefault))"
                )
            )
            .font(weight: .semibold, size: 24)
            .multilineTextAlignment(.center)

            LimitSpacer(24)

            Text("common_all_maintenance")
                .font(weight: .semibold, size: 18)
                .multilineTextAlignment(.center)

            LimitSpacer(40)

            Text("common_cs_email_description")
                .font(weight: .semibold, size: 14)
                .multilineTextAlignment(.center)

            LimitSpacer(8)

            Text(viewModel.supportEmail)
                .font(weight: .semibold, size: 14)
                .foregroundColor(.primaryDefault)
                .onTapGesture { openEmailURL() }

            Spacer()
        }
        .padding(.horizontal, 30)
        .background(.greyScaleDefault)
        .onChange(of: isMaintenanceOver) { isMaintenanceOver in
            if isMaintenanceOver { dismissHandler() }
        }
        .onReceive(remainTimer) { _ in
            guard let remainSeconds = viewModel.remainSeconds else { return }

            if remainSeconds > 0 {
                let newRemainSeconds = remainSeconds - 1
                viewModel.remainSeconds = newRemainSeconds
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

    private func openEmailURL() {
        let email = viewModel.supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }
}

private struct TimerView: View {
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
        PortalMaintenanceView(dismissHandler: {})
    }
}
