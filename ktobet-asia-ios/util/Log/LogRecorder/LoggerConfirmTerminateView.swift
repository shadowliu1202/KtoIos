import SwiftUI

struct LoggerConfirmTerminateView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = true
    
    var recordOnComplete: () -> () = {}

    var body: some View {
        Rectangle()
            .foregroundColor(.clear)
            .alert(isPresented: $showAlert) {
                SwiftUI.Alert(title: Text("要停止記錄Log嗎？"), primaryButton: .cancel(Text("停止"), action: {
                    recordOnComplete()
                    presentationMode.wrappedValue.dismiss()
                }), secondaryButton: .destructive(Text("取消"), action: {
                    presentationMode.wrappedValue.dismiss()
                }))
            }
    }
}

struct LogRecordCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerConfirmTerminateView()
    }
}
