import UIKit
import SwiftUI

class LogRecorderViewWindow: UIWindow {
    private var isRecording: Bool {
        didSet {
            configIcon()
        }
    }
    
    private let viewModel = LogRecordViewModel()
    
    override init(frame: CGRect) {
        isRecording = viewModel.manuallyLogger != nil
        super.init(frame: frame)
        windowLevel = UIWindow.Level.alert + 2
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragga)))
        
        configIcon()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configIcon() {
        if isRecording {
            let logInRecordingVC = UIHostingController(rootView: LoggerRecordingView(stopOnClick: {
                self.presentRecordCompleteAlert()
            }))
            self.rootViewController = logInRecordingVC
        } else {
            let logNotInRecordingVC = UIHostingController(rootView: LoggerEntryView(onClick: {
                self.presentStartRecordAlert()
            }))
            self.rootViewController = logNotInRecordingVC
        }
    }
    
    @objc func dragga(pan: UIPanGestureRecognizer) {
        let width = self.frame.size.width / 2
        let height = self.frame.size.height / 2
        let window = UIApplication.shared.windows[0]
        let safeFrame = window.safeAreaLayoutGuide.layoutFrame
        let location = pan.location(in: window)
        let draggedView = pan.view
        draggedView?.center = location
        
        if pan.state == .ended {
            if self.frame.midX >= safeFrame.maxX - width {
                self.center.x = safeFrame.maxX - width
            }
            
            if self.frame.midX <= safeFrame.minX + width {
                self.center.x = safeFrame.minX + width
            }
            
            if self.frame.midY >= safeFrame.maxY - height {
                self.center.y = safeFrame.maxY - height
            }
            
            if self.frame.midY <= safeFrame.minY + height {
                self.center.y = safeFrame.minY + height
            }
        }
    }
    
    private func presentStartRecordAlert() {
        let topVC = UIApplication.topViewController()
        let hostVC = UIHostingController(rootView: LoggerConfirmRecordView(recordOnStart: {
            self.viewModel.startManuallyLogger()
            self.isRecording = true
        }))
        hostVC.view.backgroundColor = UIColor.clear

        topVC?.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        topVC?.present(hostVC, animated: true, completion: nil)
    }
    
    private func presentRecordCompleteAlert() {
        let topVC = UIApplication.topViewController()
        let hostVC = UIHostingController(rootView: LoggerConfirmTerminateView(recordOnComplete: {
            self.viewModel.terminateManuallyLogger()
            self.isRecording = false
        }))
        hostVC.view.backgroundColor = UIColor.clear

        topVC?.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        topVC?.present(hostVC, animated: true, completion: nil)
    }
}
