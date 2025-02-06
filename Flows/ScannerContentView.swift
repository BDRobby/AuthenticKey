//
//  ScannerContentView.swift
//  AuthenticKey
//
//  Created by Roberto on 9/20/23.
//

import SwiftUI
import AVFoundation

/// Main QR scanner flow
struct ScannerContentView: View {
    
    @EnvironmentObject var manager: DataManager
    @State private var invalidQRData: Bool = false
    
    // MARK: - Main rendering function
    var body: some View {
        ZStack {
            QRScannerView() { qrStringValue in
                if TokenModel(uri: qrStringValue) != nil {
                    manager.addToken(withURI: qrStringValue)
                    manager.fullScreenMode = nil
                } else {
                    DispatchQueue.main.async {
                        self.invalidQRData = true
                    }
                }
            }
            .ignoresSafeArea()
            MaskedOverlay()
                .foregroundColor(.black)
                .opacity(0.8)
                .ignoresSafeArea()
            
            
            VStack {
                Text("Scan QR Code")
                    .font(.custom("GeneralSans-Medium", size: 30))
                Text("You don't have to align\nthe QR code within the frame")
                    .font(.custom("GeneralSans-Medium", size: 18))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .foregroundColor(.white).padding(.top, 50)
            
            
            VStack {
                Spacer()
                Text("Invalid QR Code data").foregroundColor(.white)
                    .font(.custom("GeneralSans-Medium", size: 25))
                    .padding()
                    .background(Color.red.cornerRadius(10)).padding(.vertical)
                    .opacity(invalidQRData ? 1 : 0)
                Button {
                    UIImpactFeedbackGenerator().impactOccurred(intensity: .greatestFiniteMagnitude)
                    manager.fullScreenMode = nil
                } label: {
                    ZStack {
                        Circle().foregroundColor(.white)
                        Image(systemName: "xmark")
                            .font(.custom("GeneralSans-Medium", size: 25))
                            .bold()
                    }
                    .foregroundColor(.black)
                }
                .frame(width: 60, height: 60)
            }
        }
    }
}

// MARK: - Preview UI
struct ScannerContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerContentView().environmentObject(DataManager())
    }
}

struct MaskedOverlay: Shape {
    private let padding: CGFloat = 50
    func path(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        let hole = RoundedRectangle(cornerRadius: 20).path(in: CGRect(x: padding, y: rect.size.height/2-(rect.size.width/2-padding), width: rect.size.width-(padding*2), height: rect.size.width-(padding*2))).reversed
        path.addPath(hole)
        return path
    }
}

extension Path {
    var reversed: Path {
        let reversedCGPath = UIBezierPath(cgPath: cgPath).reversing().cgPath
        return Path(reversedCGPath)
    }
}

// MARK: - Scanner view
struct QRScannerView: UIViewControllerRepresentable {
    var didFinishScanning: (_ result: String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController(showQRScanner: false)
        controller.completion = { value in
            didFinishScanning(value)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) { }
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var didFinishScanning: Bool = false
    private let supportedCodes: [AVMetadataObject.ObjectType] = [
        .qr
        // Add more supported object types as needed
    ]
    var completion: ((_ value: String) -> Void)?
    var showQRScanner: Bool

    init(showQRScanner: Bool) {
            self.showQRScanner = showQRScanner
            super.init(nibName: nil, bundle: nil)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Setup the camera capture session
    override func viewDidLoad() {
        super.viewDidLoad()
        #if !targetEnvironment(simulator)
            setupCaptureSession()
        #endif
    }

    /// Update the preview layer's frame
    override func viewWillLayoutSubviews() {
        previewLayer?.frame = view.layer.bounds
    }

    /// Prepare the preview layer and start capture/scan session
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if !targetEnvironment(simulator)
            if previewLayer == nil { previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) }
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            DispatchQueue.global(qos: .background).async {
                if self.captureSession?.isRunning == false { self.captureSession.startRunning() }
            }
        #endif
    }

    /// Stop scanning when the view disappears
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        #if !targetEnvironment(simulator)
            if captureSession?.isRunning == true { captureSession.stopRunning() }
        showQRScanner = false
        #endif
    }
    
    /// Setup and configure the capture session
    private func setupCaptureSession() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = supportedCodes
        }
    }
    
    /// Capture session delegate
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first, !didFinishScanning {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            UIImpactFeedbackGenerator().impactOccurred()
            didFinishScanning = true
            completion?(stringValue)
        }
    }
}

