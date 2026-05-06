//
//  ScannerCoordinator.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import Foundation

class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var parent: CodeScannerView
    var codeFound = false

    init(parent: CodeScannerView) {
        self.parent = parent
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            guard codeFound == false else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)

            // make sure we only trigger scans once per use
            codeFound = true
        }
    }

    func found(code: String) {
        parent.completion(.success(code))
    }

    func didFail(reason: ScanError) {
        parent.completion(.failure(reason))
    }
}
