import SwiftUI

struct LoggerConfirmRecordView: View {
  @Environment(\.presentationMode) var presentationMode
  @State private var showAlert = true

  var recordOnStart: () -> Void = { }

  var body: some View {
    Rectangle()
      .foregroundColor(.clear)
      .alert(isPresented: $showAlert) {
        SwiftUI.Alert(title: Text("要開始記錄Log嗎？"), message: Text("檔名預設為當下時間。"), primaryButton: .cancel(Text("開始"), action: {
          recordOnStart()
          presentationMode.wrappedValue.dismiss()
        }), secondaryButton: .destructive(Text("取消"), action: {
          presentationMode.wrappedValue.dismiss()
        }))
      }
  }
}

struct StarRecordLogView_Previews: PreviewProvider {
  static var previews: some View {
    LoggerConfirmRecordView()
  }
}
