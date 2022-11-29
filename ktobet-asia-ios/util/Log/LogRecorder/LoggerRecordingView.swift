import SwiftUI

struct LoggerRecordingView: View {
    var stopOnClick: () -> () = {}
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Button {
                stopOnClick()
            } label: {
                Image("LogInRecord")
                    .resizable()
                    .scaledToFit()
            }
            .contentShape(Rectangle())
        }
        .backgroundColor(.gray979797)
        .frame(width: 50, height: 50)
        .ignoresSafeArea()
    }
}

struct LogInRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerRecordingView()
    }
}
