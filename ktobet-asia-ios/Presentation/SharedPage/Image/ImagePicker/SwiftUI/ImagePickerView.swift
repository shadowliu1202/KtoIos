import Photos
import SwiftUI

extension ImagePickerView {
  enum PickerMode: String {
    case photo
    case qrCode
  }
  
  struct ImageAsset {
    let localIdentifier: String
    let image: UIImage
    let imageSizeInMB: Double
  }
}

struct ImagePickerView: View {
  @StateObject private var viewModel: ImagePickerViewModel
  
  private let interItemSpacing: CGFloat = 6
  private let assetsPerColumn: CGFloat = 3
  
  private let pickerMode: ImagePickerView.PickerMode
  
  private let cameraCellOnTap: () -> Void
  private let imageCellOnTap: (_ imageAsset: ImageAsset, _ isSelected: Binding<Bool>) -> Void
  
  init(
    viewModel: ImagePickerViewModel,
    pickerMode: ImagePickerView.PickerMode,
    cameraCellOnTap: @escaping () -> Void,
    imageCellOnTap: @escaping (_ imageAsset: ImageAsset, _ isSelected: Binding<Bool>) -> Void)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.pickerMode = pickerMode
    self.cameraCellOnTap = cameraCellOnTap
    self.imageCellOnTap = imageCellOnTap
  }
  
  var body: some View {
    GeometryReader { proxy in
      let itemWidth = (proxy.size.width - (interItemSpacing * (assetsPerColumn - 1))) / assetsPerColumn
      
      VStack(spacing: 0) {
        ScrollView(showsIndicators: false) {
          PageContainer(bottomPadding: 0) {
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible()), count: Int(assetsPerColumn)),
              spacing: interItemSpacing)
            {
              CameraCell(pickerMode)
                .onTapGesture {
                  cameraCellOnTap()
                }
              
              let assets = viewModel.fetchResult.objects(at: IndexSet(0..<viewModel.fetchResult.count))
              
              ForEach(assets, id: \.localIdentifier) { asset in
                let index = assets.firstIndex(of: asset) ?? 0
                
                ImageCell(
                  asset,
                  imageCellOnTap)
                  .onViewDidLoad {
                    if atPageMiddle(index) {
                      let currentPage = (index / viewModel.imagesPerPage) + 1
                      let nextPage = currentPage + 1
                      viewModel.preLoadImages(for: nextPage)
                    }
                  }
                  .frame(width: itemWidth, height: itemWidth)
              }
            }
          }
        }
      }
      .environmentObject(viewModel)
      .backgroundColor(.greyScaleBlack)
      .onViewDidLoad {
        viewModel.setup(imageSize: CGSize(width: itemWidth, height: itemWidth))
      }
    }
  }
  
  func atPageMiddle(_ currentIndex: Int) -> Bool {
    let imagesPerHalfPage = viewModel.imagesPerPage / 2
    return (currentIndex % imagesPerHalfPage == 0) && (currentIndex % viewModel.imagesPerPage != 0)
  }
}

extension ImagePickerView {
  // MARK: - CameraCell
  
  struct CameraCell: View {
    private let pickerMode: ImagePickerView.PickerMode
    
    init(_ pickerMode: ImagePickerView.PickerMode) {
      self.pickerMode = pickerMode
    }
    
    var body: some View {
      Color.from(.greyScaleChatWindow)
        .overlay(
          VStack(spacing: 8) {
            switch pickerMode {
            case .photo:
              Image("iconActionTakePhoto32")
              Text(key: "common_capture_image")
              
            case .qrCode:
              Image("Scan")
              Text(key: "cps_scan")
            }
          }
          .localized(weight: .medium, size: 14, color: .greyScaleWhite))
    }
  }
  
  // MARK: - ImageCell
  
  struct ImageCell: View {
    @EnvironmentObject private var viewModel: ImagePickerViewModel
    
    @State private var image: UIImage? = nil
    @State private var isSelected = false
    
    private let asset: PHAsset
    private let cellOnTap: (_ imageAsset: ImagePickerView.ImageAsset, _ isSelected: Binding<Bool>) -> Void
    
    init(
      _ asset: PHAsset,
      _ cellOnTap: @escaping (_ imageAsset: ImagePickerView.ImageAsset, _ isSelected: Binding<Bool>) -> Void)
    {
      self.asset = asset
      self.cellOnTap = cellOnTap
    }
    
    var body: some View {
      VStack {
        if let image {
          Color.clear
            .overlay(
              Image(uiImage: image)
                .resizable()
                .scaledToFill())
            .clipped()
        }
        else {
          SwiftUILoadingView(style: .small)
        }
      }
      .contentShape(Rectangle())
      .overlay(
        VStack {
          if isSelected {
            ImagePickerView.SelectedMark()
          }
        })
      .onTapGesture {
        guard let image else { return }
        
        cellOnTap(
          ImagePickerView.ImageAsset(
            localIdentifier: asset.localIdentifier,
            image: image,
            imageSizeInMB: viewModel.requestImageSizeInMB(asset: asset)),
          $isSelected)
      }
      .onAppear {
        guard image == nil else { return }
        
        Task {
          image = await viewModel.requestImage(for: asset)
        }
      }
    }
  }
  
  // MARK: - SelectedMark
  
  struct SelectedMark: View {
    var body: some View {
      Color.from(.greyScaleDefault)
        .opacity(0.7)
        .overlay(
          Image("iconPhotoSelected32"))
    }
  }
}

struct ImagePickerView_Previews: PreviewProvider {
  static var previews: some View {
    ImagePickerView(
      viewModel: ImagePickerViewModel(),
      pickerMode: .qrCode,
      cameraCellOnTap: { },
      imageCellOnTap: { _, _ in })
  }
}
