import youtube_ios_player_helper
import SwiftUI

struct YTPlayer: UIViewRepresentable {
        
    let videoId: String
    
    func makeUIView(context: Context) -> YTPlayerView {
        YTPlayerView()
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        uiView.load(withVideoId: videoId)
    }
}
