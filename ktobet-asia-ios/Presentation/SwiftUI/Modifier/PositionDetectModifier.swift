import SwiftUI

struct PositionDetectModifier: ViewModifier {
    @EnvironmentObject private var safeAreaMonitor: SafeAreaMonitor

    @Binding var isInTopSide: Bool

    init(result isInTopSide: Binding<Bool>) {
        _isInTopSide = isInTopSide
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader(content: { geometry in
                    Color.clear
                        .onAppear {
                            isInTopSide = calculateViewInTopSide(midY: geometry.frame(in: .global).midY)
                        }
                        .onChange(of: geometry.frame(in: .global).midY) { midY in
                            withAnimation(.easeOut(duration: 0.2)) {
                                isInTopSide = calculateViewInTopSide(midY: midY)
                            }
                        }
                        .onChange(of: safeAreaMonitor.safeAreaSize.height) { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                isInTopSide = calculateViewInTopSide(midY: geometry.frame(in: .global).midY)
                            }
                        }
                }))
    }

    private func calculateViewInTopSide(midY: CGFloat) -> Bool {
        ((midY - safeAreaMonitor.safeAreaInsets.top) / safeAreaMonitor.safeAreaSize.height) < 0.5
    }
}

extension View {
    func positionDetect(result isInTopSide: Binding<Bool>) -> some View {
        modifier(PositionDetectModifier(result: isInTopSide))
    }
}
