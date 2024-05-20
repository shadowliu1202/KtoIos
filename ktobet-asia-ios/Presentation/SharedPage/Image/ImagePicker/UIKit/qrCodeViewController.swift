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
            Logger.shared.error(error)
            return
        }
    }
}

extension qrCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        // 檢查 metadataObjects 陣列是否為非空值，它至少需包含一個物件
        guard !metadataObjects.isEmpty else { return }

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

class CornerRect: UIView {
    var color = UIColor.black {
        didSet {
            setNeedsDisplay()
        }
    }

    var radius: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var thickness: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }

    var length: CGFloat = 60 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_: CGRect) {
        color.set()

        let t2 = thickness / 2
        let path = UIBezierPath()
        // Top left
        path.move(to: CGPoint(x: t2, y: length + radius + t2))
        path.addLine(to: CGPoint(x: t2, y: radius + t2))
        path.addArc(
            withCenter: CGPoint(x: radius + t2, y: radius + t2),
            radius: radius,
            startAngle: CGFloat.pi,
            endAngle: CGFloat.pi * 3 / 2,
            clockwise: true)
        path.addLine(to: CGPoint(x: length + radius + t2, y: t2))

        // Top right
        path.move(to: CGPoint(x: frame.width - t2, y: length + radius + t2))
        path.addLine(to: CGPoint(x: frame.width - t2, y: radius + t2))
        path.addArc(
            withCenter: CGPoint(x: frame.width - radius - t2, y: radius + t2),
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi * 3 / 2,
            clockwise: false)
        path.addLine(to: CGPoint(x: frame.width - length - radius - t2, y: t2))

        // Bottom left
        path.move(to: CGPoint(x: t2, y: frame.height - length - radius - t2))
        path.addLine(to: CGPoint(x: t2, y: frame.height - radius - t2))
        path.addArc(
            withCenter: CGPoint(x: radius + t2, y: frame.height - radius - t2),
            radius: radius,
            startAngle: CGFloat.pi,
            endAngle: CGFloat.pi / 2,
            clockwise: false)
        path.addLine(to: CGPoint(x: length + radius + t2, y: frame.height - t2))

        // Bottom right
        path.move(to: CGPoint(x: frame.width - t2, y: frame.height - length - radius - t2))
        path.addLine(to: CGPoint(x: frame.width - t2, y: frame.height - radius - t2))
        path.addArc(
            withCenter: CGPoint(x: frame.width - radius - t2, y: frame.height - radius - t2),
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat.pi / 2,
            clockwise: true)
        path.addLine(to: CGPoint(x: frame.width - length - radius - t2, y: frame.height - t2))

        path.lineWidth = thickness
        path.stroke()
    }
}
