//
//  ScannerViewController.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/15/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import FactoryKit
import UIKit

#if targetEnvironment(simulator)
class ScannerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var coordinator: ScannerCoordinator?
    var useFrontCamera: Bool = true
    
    override func loadView() {
        view = UIView()
        view.isUserInteractionEnabled = true
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        label.text = "You're running in the simulator, which means the camera isn't available. Tap anywhere to send back some simulated data."
        label.textAlignment = .center
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Or tap here to select a custom image", for: .normal)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.setTitleColor(UIColor.gray, for: .highlighted)
        button.addTarget(self, action: #selector(self.openGallery), for: .touchUpInside)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 50
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let simulatedData = coordinator?.parent.simulatedData else {
			logger.error("Simulated Data Not Provided!")
            return
        }

        coordinator?.found(code: simulatedData)
    }

    @objc
    func openGallery(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let qrcodeImg = info[.originalImage] as? UIImage {
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            let ciImage = CIImage(image: qrcodeImg)!
            var qrCodeLink = ""

            let features = detector.features(in: ciImage)
            for feature in features {
                guard
                    let codeFeature = feature as? CIQRCodeFeature,
                    let codeMsg = codeFeature.messageString else { continue }
                
                qrCodeLink += codeMsg
            }

            if qrCodeLink.isEmpty {
                coordinator?.didFail(reason: .badOutput)
            } else {
                coordinator?.found(code: qrCodeLink)
            }
        } else {
			logger.error("Something went wrong")
        }
        self.dismiss(animated: true, completion: nil)
    }
}
#else
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var coordinator: ScannerCoordinator?
    var useFrontCamera: Bool = true

    @Injected(\.notificationCenter) private var notificationCenter

    override func viewDidLoad() {
        super.viewDidLoad()
        let name = Notification.Name("UIDeviceOrientationDidChangeNotification")
        notificationCenter.addObserver(self, selector: #selector(updateOrientation), name: name, object: nil)

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: useFrontCamera ? .front : .back
        ) else {
            return
        }

        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            coordinator?.didFail(reason: .badInput)
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = coordinator?.parent.codeTypes
        } else {
            coordinator?.didFail(reason: .badOutput)
            return
        }
    }

    override func viewWillLayoutSubviews() {
        previewLayer?.frame = view.layer.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        updateOrientation()
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning ?? false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc
    func updateOrientation() {
        guard let orientation = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .last?.windowScene?.interfaceOrientation else { return }
        guard let connection = captureSession.connections.last, connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
    }
}
#endif
