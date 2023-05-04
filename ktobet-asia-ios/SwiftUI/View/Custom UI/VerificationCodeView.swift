import SwiftUI

struct VerificationCodeView: View {
  @State private var selectedIndex: Int?
  @State private var cursorOpacity: Double = 1
  @State private var isFirstResponder = true

  @Binding var code: String
  let numberOfCode: Int

  init(
    code: Binding<String>,
    numberOfCode: Int = 6)
  {
    self._code = code
    self.numberOfCode = numberOfCode
  }

  var body: some View {
    ZStack {
      UIKitTextField(
        text: $code,
        isFirstResponder: $isFirstResponder,
        showPassword: .constant(false),
        isPasswordType: false,
        textFieldType: GeneralType(
          regex: .number,
          keyboardType: .numberPad,
          disablePaste: true,
          maxLength: 6),
        configuration: {
          $0.textColor = .clear
          $0.tintColor = .clear
        })
        .opacity(0.01)
        .onChange(of: code) {
          isFirstResponder = $0.count != 6
          selectedIndex = $0.count < 6 ? $0.count : nil
        }
        .onChange(of: selectedIndex) { _ in
          cursorOpacity = 1

          withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            cursorOpacity = 0
          }
        }
        .onAppear {
          selectedIndex = 0
        }

      HStack(spacing: 16) {
        ForEach(0..<6) { index in
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.from(.gray363636))
              .frame(width: 40, height: 40)

            if index < code.count {
              let startIndex = code.index(code.startIndex, offsetBy: index)
              let endIndex = code.index(startIndex, offsetBy: 1)

              Text(String(code[startIndex..<endIndex]))
                .localized(
                  weight: .semibold,
                  size: 18,
                  color: .whitePure)
            }

            if selectedIndex == index {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.from(.whitePure))
                .frame(width: 2, height: 20)
                .opacity(cursorOpacity)
                .padding(.leading, -8)
            }
          }
        }
      }
    }
    .onTapGesture {
      isFirstResponder = true
    }
  }
}

struct VerificationCodeView_Previews: PreviewProvider {
  class ViewModel: ObservableObject {
    @Published var code = ""
    let numberOfCode: Int

    init(numberOfCode: Int) {
      self.numberOfCode = numberOfCode
    }
  }

  struct Preview: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
      VStack {
        VerificationCodeView(code: $viewModel.code, numberOfCode: viewModel.numberOfCode)
      }
      .pageBackgroundColor(.gray131313)
    }
  }

  static var previews: some View {
    Preview(viewModel: .init(numberOfCode: 6))
    Preview(viewModel: .init(numberOfCode: 4))
  }
}
