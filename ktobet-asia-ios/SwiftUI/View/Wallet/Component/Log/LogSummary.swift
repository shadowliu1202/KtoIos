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
      PageContainer {
        header()

        LimitSpacer(30)
          .visibility(isResultEmpty ? .gone : .visible)

        section()
      }
      .applyTransform(when: isResultEmpty) { contentView in
        contentView
          .frame(height: safeAreaMonitor.safeAreaSize.height)
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
