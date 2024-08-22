
import SwiftUI

struct PortalMaintenanceView: View {
    @StateObject private var viewModel: PortalMaintenanceViewModel = .init()
    let dismissHandler: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Image("全站維護")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 50)

                    GeometryReader { imgGeometry in
                        HStack(spacing: 5) {
                            TimerView(timeUnit: viewModel.timerHours, unit: "h")
                            TimerView(timeUnit: viewModel.timerMinutes, unit: "m")
                            TimerView(timeUnit: viewModel.timerSeconds, unit: "s")
                        }
                        .position(x: imgGeometry.size.width * 0.51, y: imgGeometry.size.height * 0.52)
                    }
                }

                Spacer(minLength: 40)

                let fullText = Localize.string("common_maintenance_description")
                let parts = fullText.components(separatedBy: Localize.string("common_kto"))
                Group {
                    Text(parts[0])
                        .foregroundColor(Color("textPrimaryDustyGray"))
                        .font(.system(size: 24, weight: .semibold)) +
                        Text(Localize.string("common_kto"))
                        .foregroundColor(.red)
                        .font(.system(size: 24, weight: .semibold)) +
                        Text(parts[1])
                        .foregroundColor(Color("textPrimaryDustyGray"))
                        .font(.system(size: 24, weight: .semibold))
                }
                .multilineTextAlignment(.center)

                Spacer(minLength: 24)

                Text("common_all_maintenance")
                    .font(weight: .semibold, size: 18).foregroundColor(Color("textPrimaryDustyGray"))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 40)

                Text("common_cs_email_description")
                    .font(weight: .semibold, size: 14)
                    .foregroundColor(Color("textPrimaryDustyGray"))
                    .multilineTextAlignment(.center)

                Spacer(minLength: 8)

                Text(viewModel.supportEmail)
                    .font(weight: .semibold, size: 14)
                    .foregroundColor(.red)
                    .onTapGesture {
                        viewModel.openEmailURL()
                    }

                Spacer()
            }
            .padding()
        }
        .onAppear(perform: {
            viewModel.systemStatusUseCase.refreshMaintenanceState()
        })
        .background(Color("blackTwo"))
        .onChange(of: viewModel.isMaintenanceOver) { isMaintenanceOver in
            if isMaintenanceOver {
                dismissHandler()
            }
        }
    }
}

struct TimerView: View {
    let timeUnit: String
    let unit: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            Text(timeUnit)
                .font(weight: .semibold, size: 32)
                .foregroundColor(Color("textPrimaryDustyGray"))

            Text(unit)
                .font(weight: .regular, size: 12)
                .foregroundColor(Color("textPrimaryDustyGray"))
                .alignmentGuide(.bottom) { d in d[.bottom] }
        }
    }
}
