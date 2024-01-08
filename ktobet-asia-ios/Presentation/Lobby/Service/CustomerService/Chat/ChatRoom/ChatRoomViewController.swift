import Combine
import IQKeyboardManagerSwift
import Photos
import sharedbu
import SwiftUI
import UIKit

class ChatRoomViewController: CommonViewController {
  @Injected private var viewModel: ChatRoomViewModel
  @Injected private var httpClient: HttpClient
  
  private let endChatBarBtnId = 1003
  private let collapseBarBtnId = 1004
  
  private let maxCountPerUploadImage = Configuration.uploadImageCountLimit
  private let loadingView: UIView = UIHostingController(rootView: SwiftUILoadingView(backgroundOpacity: 0.8)).view
  
  private var cancellables = Set<AnyCancellable>()
  
  var barButtonItems: [UIBarButtonItem] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    binding()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    IQKeyboardManager.shared.enable = false
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    IQKeyboardManager.shared.enable = true
  }
  
  private func setupUI() {
    view.backgroundColor = .greyScaleChatWindow
    
    let chatTitle = UIBarButtonItem.kto(.text(text: Localize.string("customerservice_chat_room_title"))).isEnable(false)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont(name: "PingFangSC-Semibold", size: 16.0)!,
      .foregroundColor: UIColor.greyScaleWhite
    ]
    chatTitle.setTitleTextAttributes(attributes, for: .disabled)
    chatTitle.setTitleTextAttributes(attributes, for: .normal)
    bind(position: .left, barButtonItems: chatTitle)
    let endChat = UIBarButtonItem.kto(.customIamge(named: "End Chat")).senderId(endChatBarBtnId)
    let collapse = UIBarButtonItem.kto(.customIamge(named: "Collapse")).senderId(collapseBarBtnId)
    bind(position: .right, barButtonItems: endChat, collapse)
    additionalSafeAreaInsets.top = DIFF_NAVI_HEIGHT
    
    addSubView(from: {
      ChatRoomView(
        viewModel: viewModel,
        onChatRoomMaintain: { [weak self] in
          self?.handleMaintenance()
        },
        onTapImage: { [weak self] path in
          guard let self else { return }
          
          let urlString = self.httpClient.host.absoluteString + path
          self.toImageVC(urlString)
        },
        onTapCamera: { [weak self] in
          self?.toImagePicker()
        })
        .environment(\.playerLocale, viewModel.getSupportLocale())
    }, to: view)
    
    setupLoadingView()
  }
  
  private func setupLoadingView() {
    loadingView.backgroundColor = .clear
    navigationController?.view.addSubview(loadingView)
    loadingView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    loadingView.isHidden = true
  }
  
  private func binding() {
    viewModel.errors()
      .sink(receiveValue: { [unowned self] in handleErrors($0) })
      .store(in: &cancellables)
  }
  
  private func toExitSurvey(_ roomId: String) {
    let exitSurveyVC = ExitSurveyViewController(roomID: roomId)
    navigationController?.pushViewController(exitSurveyVC, animated: false)
  }
  
  private func dismissVC() {
    let presentingVC = navigationController?.presentingViewController
    navigationController?.dismiss(animated: true, completion: {
      NavigationManagement.sharedInstance.viewController = presentingVC
    })
  }

  private func toImagePicker() {
    let photoPickerVC = PhotoPickerViewController(
      maxCount: maxCountPerUploadImage,
      selectImagesOnComplete: { [viewModel] imageAssets in
        viewModel.sendImages(images: imageAssets)
      })
    
    self.navigationController?.pushViewController(photoPickerVC, animated: true)
  }
  
  private func toImageVC(_ url: String) {
    guard
      let vc = UIStoryboard(name: "Deposit", bundle: nil)
        .instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController else { return }
    vc.url = url
    navigationController?.pushViewController(vc, animated: true)
  }

  private func confirmNetworkThenCloseChatRoom() {
    if NetworkStateMonitor.shared.isNetworkConnected == true {
      Task {
        loadingView.isHidden = false
        await viewModel.closeChatRoom(onComplete: { exitSurveyRoomID in
          if let exitSurveyRoomID {
            toExitSurvey(exitSurveyRoomID)
          }
          else {
            dismissVC()
          }
        })
        loadingView.isHidden = true
      }
    }
    else {
      showToast(Localize.string("common_unknownhostexception"), barImg: .failed)
    }
  }
}

extension ChatRoomViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender.tag {
    case endChatBarBtnId:
      Alert.shared.show(
        Localize.string("customerservice_chat_room_close_confirm_title"),
        Localize.string("customerservice_chat_room_close_confirm_content"),
        confirm: { },
        confirmText: Localize.string("common_continue"),
        cancel: { self.confirmNetworkThenCloseChatRoom() },
        cancelText: Localize.string("common_finish"))
    case collapseBarBtnId:
      viewModel.readAllMessage(updateToLast: true, isAuto: nil)
      dismissVC()
    default:
      break
    }
  }
}
