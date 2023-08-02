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

  private var haveFailureContent: Bool {
    !(failure(KTOError.EmptyData) is EmptyView)
  }

  private var havePlaceholderContent: Bool {
    !(placeholder() is EmptyView)
  }

  init(
    url: String,
    @ViewBuilder success: @escaping (UIImage) -> Success,
    @ViewBuilder placeholder: @escaping () -> Placeholder = { EmptyView() },
    @ViewBuilder failure: @escaping (Error) -> Failure = { _ in EmptyView() })
  {
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
        if downloader.result == nil, !havePlaceholderContent {
          SwiftUIGradientArcView()
            .frame(width: 30, height: 30)
        }
        else { Color.clear }
      }
    }
    .applyTransform(when: !haveFailureContent) { contentView in
      contentView
        .visibility(downloader.result?.error == nil ? .visible : .gone)
    }
    .onAppear {
      Task {
        await downloader.image(
          from: url,
          startWith: havePlaceholderContent ? .placeholder : nil)
      }
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
