import SwiftUI

struct LoggerEntryView: View {
    var onClick: () -> () = {}
    
    var body: some View {
        Button {
            onClick()
        } label: {
            Image("LaunchLogRecording")
                .resizable()
                .scaledToFit()
        }
        .frame(width: 50)
        .ignoresSafeArea()
    }
}

struct LogNotInRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerEntryView()
    }
}
