import SwiftUI

struct FrameDetecter: ViewModifier {
    private let onAppearPerform: ((_ frame: CGRect) -> Void)?
    private let onChangePerform: ((_ frame: CGRect) -> Void)?

    init(
        onAppearPerform: ((_ frame: CGRect) -> Void)?,
        onChangePerform: ((_ frame: CGRect) -> Void)?)
    {
        self.onAppearPerform = onAppearPerform
        self.onChangePerform = onChangePerform
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            onAppearPerform?(proxy.frame(in: .global))
                        }
                        .onChange(of: proxy.frame(in: .global)) { newFrame in
                            onChangePerform?(newFrame)
                        }
                })
    }
}

struct FrameDetecter_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, world!")
            .frameDetecter(
                onAppear: { _ in
                    print("hi")
                },
                onChange: { _ in
                    print("ho")
                })
    }
}

extension View {
    func frameDetecter(
        onAppear onAppearPerform: ((_ frame: CGRect) -> Void)? = nil,
        onChange onChangePerform: ((_ frame: CGRect) -> Void)? = nil)
        -> some View
    {
        modifier(FrameDetecter(
            onAppearPerform: onAppearPerform,
            onChangePerform: onChangePerform))
    }

    func frameDetecter(onPerform: @escaping ((_ frame: CGRect) -> Void)) -> some View {
        modifier(FrameDetecter(
            onAppearPerform: onPerform,
            onChangePerform: onPerform))
    }
}
