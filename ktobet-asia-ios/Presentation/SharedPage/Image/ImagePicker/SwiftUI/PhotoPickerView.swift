import Photos
import SwiftUI

struct PhotoPickerView: View {
  @State private var selectedImages: [ImagePickerView.ImageAsset] = []
  
  private let viewModel: ImagePickerViewModel
  
  private let availableFormat = ["PNG", "JPG", "BMP", "JPEG", "HEIF", "HEIC"]
  private let maxCount: Int
  private let maxImageSizeInMB: Int
  
  private let cameraCellOnTap: () -> Void
  private let countLimitOnHit: () -> Void
  private let invalidFormatOnHit: () -> Void
  private let imageSizeLimitOnHit: () -> Void
  private let submitButtonOnTap: (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void
  
  init(
    viewModel: ImagePickerViewModel,
    maxCount: Int,
    maxImageSizeInMB: Int,
    cameraCellOnTap: @escaping () -> Void,
    countLimitOnHit: @escaping () -> Void,
    invalidFormatOnHit: @escaping () -> Void,
    imageSizeLimitOnHit: @escaping () -> Void,
    submitButtonOnTap: @escaping (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void)
  {
    self.viewModel = viewModel
    self.maxCount = maxCount
    self.maxImageSizeInMB = maxImageSizeInMB
    self.cameraCellOnTap = cameraCellOnTap
    self.countLimitOnHit = countLimitOnHit
    self.invalidFormatOnHit = invalidFormatOnHit
    self.imageSizeLimitOnHit = imageSizeLimitOnHit
    self.submitButtonOnTap = submitButtonOnTap
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ImagePickerView(
        viewModel: viewModel,
        pickerMode: .photo,
        cameraCellOnTap: cameraCellOnTap,
        imageCellOnTap: toggleSelection)
        
      SelectionStatusBar(
        selectedImages,
        maxCount,
        submitButtonOnTap)
    }
    .backgroundColor(.greyScaleBlack, ignoresSafeArea: .all)
  }
  
  func toggleSelection(_ imageAsset: ImagePickerView.ImageAsset, _ isSelected: Binding<Bool>) {
    if selectedImages.contains(where: { $0.asset.localIdentifier == imageAsset.asset.localIdentifier }) {
      removeSelection(imageAsset, isSelected)
    }
    else {
      addSelection(imageAsset, isSelected)
    }
  }
  
  func removeSelection(_ imageAsset: ImagePickerView.ImageAsset, _ isSelected: Binding<Bool>) {
    selectedImages.removeAll(where: { $0.asset.localIdentifier == imageAsset.asset.localIdentifier })
    isSelected.wrappedValue = false
  }
  
  func addSelection(_ imageAsset: ImagePickerView.ImageAsset, _ isSelected: Binding<Bool>) {
    guard selectedImages.count < maxCount
    else {
      countLimitOnHit()
      return
    }
    
    guard Int(viewModel.getSizeInMB(asset: imageAsset.asset)) < maxImageSizeInMB
    else {
      imageSizeLimitOnHit()
      return
    }
    
    guard isFileExtensionAvailable(fileName: viewModel.getFileName(asset: imageAsset.asset))
    else {
      invalidFormatOnHit()
      return
    }
    
    selectedImages.append(imageAsset)
    isSelected.wrappedValue = true
  }
  
  private func isFileExtensionAvailable(fileName: String) -> Bool {
    let fileExtension = fileName.split(separator: ".").last?.uppercased() ?? ""
    return availableFormat.contains(fileExtension)
  }
}

extension PhotoPickerView {
  // MARK: - SelectionStatusBar
  
  struct SelectionStatusBar: View {
    private let selectedImages: [ImagePickerView.ImageAsset]
    private let maxAmount: Int
    private let submitButtonOnTap: (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void
    
    init(
      _ selectedImages: [ImagePickerView.ImageAsset],
      _ maxAmount: Int,
      _ submitButtonOnTap: @escaping (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void)
    {
      self.selectedImages = selectedImages
      self.maxAmount = maxAmount
      self.submitButtonOnTap = submitButtonOnTap
    }
    
    var body: some View {
      HStack(spacing: 8) {
        HStack(spacing: 8) {
          Image("Photo")
          
          Text(selectedImages.count.description + "/" + maxAmount.description)
            .localized(weight: .regular, size: 16, color: .textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        
        Button(
          action: {
            submitButtonOnTap(selectedImages)
          },
          label: {
            Text(key: "common_upload")
              .localized(weight: .regular, size: 16, color: .primaryDefault)
          })
          .buttonStyle(.plain)
          .disabled(selectedImages.isEmpty)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 24)
      .backgroundColor(.greyScaleBlack)
    }
  }
}

struct PhotoPickerView_Previews: PreviewProvider {
  static var previews: some View {
    PhotoPickerView(
      viewModel: ImagePickerViewModel(),
      maxCount: 3,
      maxImageSizeInMB: 10,
      cameraCellOnTap: { },
      countLimitOnHit: { },
      invalidFormatOnHit: { },
      imageSizeLimitOnHit: { },
      submitButtonOnTap: { _ in })
  }
}
