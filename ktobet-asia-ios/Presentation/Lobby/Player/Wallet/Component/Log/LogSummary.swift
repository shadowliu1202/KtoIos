import SwiftUI

@available(*, deprecated, message: "Waiting for refactor.")
struct LogSummary<Header, Section>: View
    where
    Header: View,
    Section: View
{
    @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor

    let header: () -> Header
    let section: () -> Section

    let isResultEmpty: Bool
    let isLoading: Bool

    var onBottomReached: (() -> Void)?

    var body: some View {
        DelegatedScrollView {
            Group {
                if isResultEmpty {
                    PageContainer(bottomPadding: 0) {
                        header()
            
                        section()
                    }
                    .frame(height: safeAreaMonitor.safeAreaSize.height)
                }
                else {
                    PageContainer {
                        header()
            
                        LimitSpacer(30)
            
                        section()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        onBottomReached: {
            onBottomReached?()
        }
        .onPageLoading(isLoading)
        .pageBackgroundColor(.greyScaleDefault)
    }
}
