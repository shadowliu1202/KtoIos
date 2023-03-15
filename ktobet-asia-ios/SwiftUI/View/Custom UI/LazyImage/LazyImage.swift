import SwiftUI

struct LazyImage<Success, Placeholder, Failure>: View
  where
  Success: View,
  Placeholder: View,
  Failure: View
{
  @StateObject fileprivate var downloader: Downloader = .init()

  private let url: String

  private let success: (UIImage) -> Success
  private let placeholder: () -> Placeholder
  private let failure: (Error) -> Failure

  private var headers: [String: String]?

  private var haveFailureContent: Bool {
    !(failure(KTOError.EmptyData) is EmptyView)
  }

  private var havePlaceholderContent: Bool {
    !(placeholder() is EmptyView)
  }

  init(
    headers: [String: String]? = nil,
    url: String,
    @ViewBuilder success: @escaping (UIImage) -> Success,
    @ViewBuilder placeholder: @escaping () -> Placeholder = { EmptyView() },
    @ViewBuilder failure: @escaping (Error) -> Failure = { _ in EmptyView() })
  {
    self.headers = headers
    self.url = url
    self.success = success
    self.placeholder = placeholder
    self.failure = failure
  }

  var body: some View {
    VStack {
      switch downloader.result {
      case .success(let image):
        success(image)

      case .failure(let error):
        failure(error)

      case .placeholder:
        placeholder()

      default:
        Color.clear
          .if(downloader.result == nil && !havePlaceholderContent) {
            $0.overlay(
              SwiftUIGradientArcView(isVisible: true)
                .frame(width: 30, height: 30))
          }
      }
    }
    .if(!haveFailureContent) {
      $0.visibility(downloader.result?.error == nil ? .visible : .gone)
    }
    .onAppear {
      downloader.headers = headers
      downloader.image(
        from: url,
        startWith: havePlaceholderContent ? .placeholder : nil)
    }
  }
}

struct LazyImage_Previews: PreviewProvider {
  static var previews: some View {
    LazyImage(
      url: "https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/store-card-14-16-mac-nav-202301?wid=200&hei=130&fmt=png-alpha&.v=1670959891635",
      success: {
        Image(uiImage: $0)
          .resizable()
          .scaledToFit()
      },
      placeholder: {
        Text("Loading")
      },
      failure: { _ in
        Image("Failed")
          .resizable()
          .scaledToFit()
      })
      .frame(width: 300, height: 300)
      .backgroundColor(.darkGray)

    LazyImage(
      url: "https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/store-card-14-16-mac-nav-202301?wid=200&hei=130&fmt=png-alpha&.v=1670959891635",
      success: {
        Image(uiImage: $0)
          .resizable()
          .scaledToFit()
      },
      failure: { _ in
        Image("Failed")
          .resizable()
          .scaledToFit()
      })
      .frame(width: 300, height: 300)
      .backgroundColor(.darkGray)

    HStack {
      LazyImage(
        url: "hts",
        success: {
          Image(uiImage: $0)
            .resizable()
            .scaledToFit()
        })
        .frame(width: 300, height: 300)
        .backgroundColor(.darkGray)
    }
  }
}
