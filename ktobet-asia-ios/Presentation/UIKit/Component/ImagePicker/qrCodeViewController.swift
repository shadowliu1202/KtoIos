import AVFoundation
import UIKit

class qrCodeViewController: UIViewController {
  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var qrCodeFrameView: UIView?
  var qrCodeCompletion: ((_ qrCodeString: String) -> Void)?

  let supportedBarCodes = [AVMetadataObject.ObjectType.qr]

  private var isFirstGetQRCode = true

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    qrCodeCamera()
  }

  private func qrCodeCamera() {
    guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)

      // Initialize the captureSession object.
      captureSession = AVCaptureSession()
      // Set the input device on the capture session.
      captureSession?.addInput(input)

      // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureSession?.addOutput(captureMetadataOutput)

      // Set delegate and use the default dispatch queue to execute the call back
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

      // Detect all the supported bar code
      captureMetadataOutput.metadataObjectTypes = supportedBarCodes

      // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
      let layerFrame = CGRect(x: 0, y: 200, width: self.view.frame.width, height: self.view.frame.height * 0.5)
      videoPreviewLayer?.frame = layerFrame
      view.layer.addSublayer(videoPreviewLayer!)

      let titleLabel = UILabel()
      titleLabel.text = Localize.string("cps_scan_qrcode")
      titleLabel.font = UIFont(name: "PingFangSC-Semibold", size: 24)
      titleLabel.textColor = UIColor.white
      titleLabel.textAlignment = .center
      titleLabel.sizeToFit()
      titleLabel.center.x = view.center.x
      titleLabel.center.y = 160
      view.addSubview(titleLabel)

      qrCodeFrameView = UIView()
      qrCodeFrameView?.frame = layerFrame
      if let qrCodeFrameView {
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)

        let height = qrCodeFrameView.frame.height * 0.8
        let width = qrCodeFrameView.frame.width * 0.8
        let center = CGPoint(
          x: qrCodeFrameView.frame.size.width / 2,
          y: qrCodeFrameView.frame.size.height / 2)
        let cr = CornerRect(frame: CGRect(x: 0, y: 0, width: width, height: height))
        cr.center = center
        cr.color = UIColor(red: 254 / 255, green: 213 / 255, blue: 0 / 255, alpha: 1)
        cr.thickness = 4
        cr.backgroundColor = .clear
        qrCodeFrameView.addSubview(cr)

        let label = UILabel()
        label.font = UIFont(name: "PingFangSC-Semibold", size: 60)
        label.textAlignment = .center
        label.text = "＋"
        label.textColor = UIColor(red: 254 / 255, green: 213 / 255, blue: 0 / 255, alpha: 1)
        label.sizeToFit()
        label.center = center
        qrCodeFrameView.addSubview(label)

        captureSession?.startRunning()
      }
    }
    catch {
      // If any error occurs, simply print it out and don't continue any more.
      Logger.shared.debug(error.localizedDescription)
      return
    }
  }
}

extension qrCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
    // 檢查 metadataObjects 陣列是否為非空值，它至少需包含一個物件
    if metadataObjects.count == 0 {
      Logger.shared.debug("No QR code is detected")
      return
    }

    // 取得元資料（metadata）物件
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    if supportedBarCodes.contains(metadataObj.type) {
      if metadataObj.stringValue != nil, isFirstGetQRCode {
        qrCodeCompletion?(metadataObj.stringValue ?? "")
        isFirstGetQRCode = false
      }
    }
  }
}
