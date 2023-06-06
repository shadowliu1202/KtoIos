import SwiftUI
import youtube_ios_player_helper

struct YTPlayer: UIViewRepresentable {
  let videoId: String

  func makeUIView(context _: Context) -> YTPlayerView {
    YTPlayerView()
  }

  func updateUIView(_ uiView: YTPlayerView, context _: Context) {
    uiView.load(withVideoId: videoId)
  }
}
